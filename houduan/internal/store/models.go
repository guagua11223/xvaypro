package store

type User struct {
	ID                int64
	Username          string
	Email             string
	PasswordHash      string
	UUID              string
	Hy2Password       string
	SubToken          string
	Upload            int64
	Download          int64
	Total             int64
	ExpireAt          int64
	Status            string
	DeviceLimit       int64
	CreatedAt         int64
	Nickname          string
	Avatar            string
	UserType          string
	ReferrerID        int64
	DistributorID     int64
	IsDistributor     int
	IsAgent           int
	CommissionMode    int
	WalletEnabled     int
	CanAuthorizeAgent int
	EmailStatus       int
	InviteCode        string
	DistributorRate   int
	MemberRate        int
}

type UserInput struct {
	Username    string
	Email       string
	Nickname    string
	Avatar      string
	UserType    string
	Password    string
	Total       int64
	ExpireAt    int64
	Status      string
	DeviceLimit int64
}

type UserPatch struct {
	Username    *string
	Email       *string
	Nickname    *string
	Avatar      *string
	UserType    *string
	Password    *string
	Total       *int64
	ExpireAt    *int64
	Status      *string
	DeviceLimit *int64
	Upload      *int64
	Download    *int64
}

type Node struct {
	ID                 int64
	Name               string
	Region             string
	CountryCode        string
	Host               string
	SortOrder          int64
	Enabled            bool
	Remark             string
	Secret             string
	XrayEnabled        bool
	XrayPort           int
	XrayAPIPort        int
	RealityPrivateKey  string
	RealityPublicKey   string
	RealityShortIDs    string
	RealitySNI         string
	RealityDest        string
	RealitySpiderX     string
	RealityFingerprint string
	RealityFlow        string
	Hy2Enabled         bool
	Hy2Port            int
	Hy2SNI             string
	Hy2Insecure        bool
	Hy2ObfsPassword    string
	Hy2UpMbps          int
	Hy2DownMbps        int
	Hy2CertPath        string
	Hy2KeyPath         string
	Hy2Masquerade      string
	Hy2StatsSecret     string
	LastSeenAt         int64
	CreatedAt          int64
}

type NodeInput struct {
	Name               string
	Region             string
	CountryCode        string
	Host               string
	SortOrder          int64
	Enabled            bool
	Remark             string
	XrayEnabled        bool
	XrayPort           int
	XrayAPIPort        int
	RealityPrivateKey  string
	RealityPublicKey   string
	RealityShortIDs    []string
	RealitySNI         string
	RealityDest        string
	RealitySpiderX     string
	RealityFingerprint string
	RealityFlow        string
	Hy2Enabled         bool
	Hy2Port            int
	Hy2SNI             string
	Hy2Insecure        bool
	Hy2ObfsPassword    string
	Hy2UpMbps          int
	Hy2DownMbps        int
	Hy2CertPath        string
	Hy2KeyPath         string
	Hy2Masquerade      string
}

type NodePatch struct {
	Name                 *string
	Region               *string
	CountryCode          *string
	Host                 *string
	SortOrder            *int64
	Enabled              *bool
	Remark               *string
	XrayEnabled          *bool
	XrayPort             *int
	XrayAPIPort          *int
	RealityPrivateKey    *string
	RealityPublicKey     *string
	RealityShortIDs      []string
	RealitySNI           *string
	RealityDest          *string
	RealitySpiderX       *string
	RealityFingerprint   *string
	RealityFlow          *string
	Hy2Enabled           *bool
	Hy2Port              *int
	Hy2SNI               *string
	Hy2Insecure          *bool
	Hy2ObfsPassword      *string
	Hy2UpMbps            *int
	Hy2DownMbps          *int
	Hy2CertPath          *string
	Hy2KeyPath           *string
	Hy2Masquerade        *string
	RotateRealityKeys    bool
	RotateSecret         bool
	RotateHy2StatsSecret bool
}

type Announcement struct {
	ID        int64  `json:"id"`
	Title     string `json:"title"`
	Body      string `json:"body"`
	Enabled   int    `json:"enabled"`
	CreatedAt int64  `json:"created_at"`
}

type TrafficEntry struct {
	UUID     string
	Email    string
	UserID   *int64
	Upload   int64
	Download int64
}

type TrafficRow struct {
	ID       int64  `json:"id"`
	Email    string `json:"email"`
	Upload   int64  `json:"upload"`
	Download int64  `json:"download"`
	Total    int64  `json:"total"`
}

type TrafficResult struct {
	Updated []TrafficRow `json:"updated"`
	Unknown []any        `json:"unknown"`
}
