package api

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"io"
	"log"
	"net/http"
	"strconv"
	"strings"

	"xvay/houduan/internal/errs"
)

const maxBody = 1_000_000

type ctxKey int

const paramsKey ctxKey = 1

type handler func(http.ResponseWriter, *http.Request) error

type route struct {
	method  string
	pattern string
	handle  handler
}

func (s *Server) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	defer func() {
		if recovered := recover(); recovered != nil {
			log.Printf("panic: %v", recovered)
			writeFail(w, http.StatusInternalServerError, "INTERNAL", "服务器内部错误")
		}
	}()
	w.Header().Set("Cache-Control", "no-store")
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Headers", "authorization, content-type, x-node-secret")
	w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PATCH, PUT, DELETE, OPTIONS")
	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusNoContent)
		return
	}
	actual := splitPath(r.URL.Path)
	for _, route := range s.routes {
		if route.method != r.Method {
			continue
		}
		params, ok := matchPath(splitPath(route.pattern), actual)
		if !ok {
			continue
		}
		err := route.handle(w, r.WithContext(context.WithValue(r.Context(), paramsKey, params)))
		if err != nil {
			writeErr(w, err)
		}
		return
	}
	writeFail(w, http.StatusNotFound, "NOT_FOUND", "接口不存在")
}

func param(r *http.Request, name string) string {
	params, _ := r.Context().Value(paramsKey).(map[string]string)
	return params[name]
}

func idParam(r *http.Request) (int64, error) {
	raw := param(r, "id")
	if raw == "" {
		return 0, errs.New(http.StatusNotFound, "NOT_FOUND", "资源不存在")
	}
	for _, c := range raw {
		if c < '0' || c > '9' {
			return 0, errs.New(http.StatusNotFound, "NOT_FOUND", "资源不存在")
		}
	}
	id, err := strconv.ParseInt(raw, 10, 64)
	if err != nil {
		return 0, errs.New(http.StatusNotFound, "NOT_FOUND", "资源不存在")
	}
	return id, nil
}

func queryLimit(r *http.Request) (int, error) {
	raw := r.URL.Query().Get("limit")
	if raw == "" {
		return 200, nil
	}
	n, err := strconv.Atoi(raw)
	if err != nil || n < 1 {
		return 0, errs.New(http.StatusBadRequest, "VALIDATION", "limit 不正确")
	}
	if n > 500 {
		return 500, nil
	}
	return n, nil
}

func readJSON(r *http.Request) (map[string]any, error) {
	if r.Method == http.MethodGet || r.Method == http.MethodHead || r.Body == nil {
		return map[string]any{}, nil
	}
	defer r.Body.Close()
	buf, err := io.ReadAll(io.LimitReader(r.Body, maxBody+1))
	if err != nil {
		return nil, errs.New(http.StatusBadRequest, "VALIDATION", "读取请求失败")
	}
	if len(buf) > maxBody {
		return nil, errs.New(http.StatusRequestEntityTooLarge, "VALIDATION", "请求体过大")
	}
	if len(bytes.TrimSpace(buf)) == 0 {
		return map[string]any{}, nil
	}
	dec := json.NewDecoder(bytes.NewReader(buf))
	dec.UseNumber()
	var body any
	if err := dec.Decode(&body); err != nil || dec.More() {
		return nil, errs.New(http.StatusBadRequest, "VALIDATION", "JSON 格式不正确")
	}
	obj, ok := body.(map[string]any)
	if !ok {
		return nil, errs.New(http.StatusBadRequest, "VALIDATION", "请求体必须是 JSON 对象")
	}
	return obj, nil
}

func writeOK(w http.ResponseWriter, status int, data any) {
	writeJSON(w, status, map[string]any{"ok": true, "data": data})
}

func writeJSON(w http.ResponseWriter, status int, body any) {
	payload, err := marshal(body)
	if err != nil {
		log.Printf("encode: %v", err)
		writeFail(w, http.StatusInternalServerError, "INTERNAL", "服务器内部错误")
		return
	}
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	_, _ = w.Write(payload)
}

func writeText(w http.ResponseWriter, status int, text string, headers map[string]string) {
	for key, value := range headers {
		w.Header().Set(key, value)
	}
	w.Header().Set("Content-Type", "text/plain; charset=utf-8")
	w.WriteHeader(status)
	_, _ = w.Write([]byte(text))
}

func writeFail(w http.ResponseWriter, status int, code, message string) {
	writeJSON(w, status, map[string]any{
		"ok": false,
		"error": map[string]string{
			"code":    code,
			"message": message,
		},
	})
}

func writeErr(w http.ResponseWriter, err error) {
	var httpErr *errs.HTTP
	if errors.As(err, &httpErr) {
		writeFail(w, httpErr.Status, httpErr.Code, httpErr.Message)
		return
	}
	log.Printf("request error: %v", err)
	writeFail(w, http.StatusInternalServerError, "INTERNAL", "服务器内部错误")
}

func marshal(value any) ([]byte, error) {
	var buf bytes.Buffer
	enc := json.NewEncoder(&buf)
	enc.SetEscapeHTML(false)
	if err := enc.Encode(value); err != nil {
		return nil, err
	}
	return buf.Bytes(), nil
}

func splitPath(path string) []string {
	path = strings.Trim(path, "/")
	if path == "" {
		return nil
	}
	return strings.Split(path, "/")
}

func matchPath(expected, actual []string) (map[string]string, bool) {
	if len(expected) != len(actual) {
		return nil, false
	}
	params := map[string]string{}
	for i := range expected {
		if strings.HasPrefix(expected[i], ":") {
			params[expected[i][1:]] = actual[i]
			continue
		}
		if expected[i] != actual[i] {
			return nil, false
		}
	}
	return params, true
}
