window.XVAY = {
  plans: [
    { id: "week", days: 7, priceZh: "¥12", priceEn: "$2", nameZh: "7 天", nameEn: "7 days", noteZh: "先用一周看看", noteEn: "Try a full week" },
    { id: "month", days: 30, priceZh: "¥28", priceEn: "$4", nameZh: "1 个月", nameEn: "1 month", noteZh: "最常被选", noteEn: "Most picked", featured: true },
    { id: "quarter", days: 90, priceZh: "¥68", priceEn: "$10", nameZh: "3 个月", nameEn: "3 months", noteZh: "够用一个季节", noteEn: "A season of access" },
    { id: "year", days: 365, priceZh: "¥168", priceEn: "$24", nameZh: "12 个月", nameEn: "12 months", noteZh: "算下来最省", noteEn: "Lowest by month" }
  ],
  reviews: [
    { name: "陈予安", date: "2026.08.12", zh: "打开就能用，几乎不用管线路。出差两周没断过。", en: "It just connects. I barely touch the line list, and a two-week trip stayed online." },
    { name: "Mia Chen", date: "2026.07.03", zh: "客服把节点问题讲清楚了，没有把我推去一串设置。", en: "Support explained the node issue plainly, without sending me through a maze of settings." },
    { name: "周岚", date: "2026.06.21", zh: "周卡很合适。我只是短期要用，不想被年费套住。", en: "The weekly plan fits. I only needed it for a short stretch and didn't want a yearly lock-in." },
    { name: "Owen Park", date: "2026.05.18", zh: "手机和笔记本同时在线，账号不用来回挤。", en: "Phone and laptop stay on together. I don't have to kick one session off." },
    { name: "林夏", date: "2026.04.09", zh: "试用三天就决定留下来，主要是因为少掉线。", en: "Three days of the trial were enough. It drops less often than what I used before." },
    { name: "Helena Voss", date: "2026.03.30", zh: "界面干净，连接按钮一眼就找到。", en: "The interface is quiet. The connect button is obvious." },
    { name: "许知行", date: "2026.02.14", zh: "晚上看视频不太卡，延迟数字也稳。", en: "Evening video stayed smooth, and the latency figure didn't jump around." },
    { name: "Noah Abebe", date: "2026.01.27", zh: "注册完就能试用，没有先绑支付方式。", en: "The trial started right after signup. No payment method first." }
  ],
  categories: [
    { id: "start", zh: "开始使用", en: "Start" },
    { id: "connect", zh: "连接", en: "Connection" },
    { id: "account", zh: "账户", en: "Account" },
    { id: "device", zh: "设备", en: "Devices" },
    { id: "billing", zh: "会员", en: "Plans" }
  ],
  faqs: [
    { cat: "start", qZh: "怎样领取 72 小时试用？", qEn: "How do I start the 72-hour trial?", aZh: "注册一个账号即可。试用从注册成功时开始计算，不需要先绑定支付方式。到期后连接会停，账户还在。", aEn: "Create an account. The trial starts when registration succeeds, with no payment method required. When it ends, the connection stops and the account remains." },
    { cat: "start", qZh: "支持哪些系统？", qEn: "Which systems are supported?", aZh: "macOS、Windows、iOS、Android 和 Linux。同一个会员可以在这些设备之间使用。", aEn: "macOS, Windows, iOS, Android, and Linux. One membership works across them." },
    { cat: "connect", qZh: "连上之后网页打不开？", qEn: "Connected, but pages won't load?", aZh: "先换一条线路再试。如果只有某一个网站打不开，多半是对方的访问策略，换地区通常比反复重连有用。也可以关掉客户端再开一次。", aEn: "Switch lines once. If only one site fails, its own access rules are the likely cause, and another region helps more than reconnecting in a loop. You can also quit the app and open it again." },
    { cat: "connect", qZh: "速度突然变慢？", qEn: "Why did it suddenly get slow?", aZh: "高峰时段热门线路会挤。换到延迟更低的一条，或避开刚连接时的默认线路。本地网络本身不稳时，VPN 没法把带宽变多。", aEn: "Popular lines crowd up at peak hours. Pick a lower-latency line instead of staying on the default. A VPN cannot add bandwidth your local network doesn't have." },
    { cat: "account", qZh: "忘记密码了？", qEn: "Forgot the password?", aZh: "这个官网演示把账户放在你自己的浏览器里，没有邮件找回。可以在登录页删除提示所说的本机账户后重新注册。正式环境才会接邮箱重置。", aEn: "This demo keeps accounts in your browser and has no email reset. Remove the local account from the sign-in page and register again. A production setup would reset by email." },
    { cat: "account", qZh: "试用和付费会员有什么区别？", qEn: "How is the trial different from a paid plan?", aZh: "试用 72 小时，线路和设备数与会员相同。区别是时长。试用结束不会自动变成付费，也不会扣款。", aEn: "The trial lasts 72 hours with the same lines and device limit. It does not turn into a paid plan and nothing is charged." },
    { cat: "device", qZh: "可以几台设备同时在线？", qEn: "How many devices can stay online?", aZh: "最多 5 台。超出时，在账户页移除一台不再使用的设备即可。", aEn: "Up to five. If you pass that, remove an unused device on the account page." },
    { cat: "device", qZh: "如何移除设备？", qEn: "How do I remove a device?", aZh: "登录后打开账户页的设备列表，点移除。当前这台浏览器也可以移除，移除后需要重新登录。", aEn: "Open the device list on the account page and choose Remove. You can remove this browser too; you'll need to sign in again." },
    { cat: "billing", qZh: "会自动续费吗？", qEn: "Does it auto-renew?", aZh: "不会。会员到期就停止，不会用同一张卡再扣下一期。想继续用，再选一次时长。", aEn: "No. The plan stops when the term ends. Nothing is charged again unless you pick a new term." },
    { cat: "billing", qZh: "这里的开通是真的扣款吗？", qEn: "Will checkout charge me?", aZh: "不是。当前官网是界面演示，开通只会写进浏览器本地，用来展示到期时间和订单号，不会发生支付。", aEn: "No. This site is a demo. Choosing a plan only saves it in your browser so you can see the expiry and an order number. No payment runs." }
  ],
  posts: [
    {
      id: "pick-a-line",
      date: "2026-09-12",
      tagZh: "连接",
      tagEn: "Connection",
      titleZh: "线路不要收藏，看延迟就好",
      titleEn: "Don't bookmark a line. Watch the latency.",
      excerptZh: "固定死一条「上次很快」的线路，往往是变慢的原因。",
      excerptEn: "Pinning yesterday's fast line is a common reason today feels slow.",
      bodyZh: [
        "很多人会把某条线路当成固定选择。它昨天快，不代表这个时段还快。线路质量取决于你现在的网络、出口是否拥挤，以及目标网站离哪边更近。",
        "飞连 默认会自己选一条。你只有在视频发涩、网页打转时才需要动手：打开线路列表，挑延迟数字更低的一条，而不是挑名字看起来高级的一条。",
        "如果换了三条仍然慢，先用普通网络打开一个国内或本地页面。本地本身不通时，换线路没有帮助。",
        "旅行时也一样。酒店网络经常限制长时间连接，掉线后让客户端重选一次，比手动指定家乡那条线路更稳。"
      ],
      bodyEn: [
        "People pin a line because it was fast yesterday. That says little about this hour. Quality depends on your current network, how crowded the exit is, and where the site you want actually sits.",
        "飞连 picks a line for you. Step in only when video stutters or pages spin: open the list and choose a lower latency, not a fancier name.",
        "If three lines are still slow, open a local page without the VPN. When the local network is the problem, another line will not fix it.",
        "Hotel networks often drop long sessions. After a drop, let the app choose again instead of forcing the line you use at home."
      ]
    },
    {
      id: "trial",
      date: "2026-08-02",
      tagZh: "账户",
      tagEn: "Account",
      titleZh: "72 小时试用，建议这样用完",
      titleEn: "How to spend the 72-hour trial",
      excerptZh: "别只在第一分钟点一下。把你真正的一天走一遍。",
      excerptEn: "Don't judge it in the first minute. Walk through a real day.",
      bodyZh: [
        "试用和付费会员的线路相同，所以这 72 小时足够判断它适不适合你，而不只是看连接动画好不好看。",
        "第一天用你平时最在意的两件事：一段长视频，以及一个要一直挂着的工作页面。只测速不做事，很容易误判。",
        "第二天把手机和电脑一起挂上，确认设备数和切换是否顺手。账户页能看到已经登录的设备。",
        "试用结束不会扣费。如果合适，再选 7 天或 1 个月。不合适就停，账户可以留着。"
      ],
      bodyEn: [
        "The trial uses the same lines as a paid plan, so 72 hours is enough to judge a real fit, not just the connect animation.",
        "On day one, do the two things you actually care about: a long video, and a work page that stays open. A speed test alone misleads.",
        "On day two, keep the phone and computer on together and check the device list.",
        "The trial does not charge you. If it fits, pick 7 days or a month. If not, stop. The account can stay."
      ]
    },
    {
      id: "devices",
      date: "2026-06-19",
      tagZh: "设备",
      tagEn: "Devices",
      titleZh: "一个账号，怎么在手机和电脑上一起用",
      titleEn: "One account on your phone and computer",
      excerptZh: "不用退出再登。五台之内同时在线。",
      excerptEn: "No sign-out relay. Up to five stay on at once.",
      bodyZh: [
        "在每台设备上登录同一个邮箱即可。会员不是绑死在第一台手机上的。",
        "同时在线的上限是 5 台。平板、手机、家里的台式机和公司的笔记本，一般够用。",
        "旧设备不要留着占名额。账户页会列出最近登录的设备，移除后那个会话就失效。",
        "公共电脑用完记得退出。演示版的数据只在那台浏览器里，正式客户端也会把会话留在本机。"
      ],
      bodyEn: [
        "Sign in with the same email on each device. The plan is not glued to the first phone.",
        "Five devices can stay online: a tablet, a phone, a home desktop, and a work laptop usually fit.",
        "Don't leave old devices taking a slot. The account page lists recent sign-ins, and removing one ends that session.",
        "Sign out of shared computers. This demo stores data in that browser; a production app keeps its session on the device too."
      ]
    },
    {
      id: "no-renewal",
      date: "2026-04-28",
      tagZh: "产品",
      tagEn: "Product",
      titleZh: "为什么会员不会自动续费",
      titleEn: "Why plans don't renew themselves",
      excerptZh: "到期就停。想继续，再选一次。",
      excerptEn: "It stops at the end. You choose again if you want more.",
      bodyZh: [
        "很多网络工具把人留住的办法是默认续费，取消入口再藏深一点。飞连 反过来：到期即停。",
        "短周期因此才有意义。你可能只需要出国的那两周，或者项目联调的那几天。用完就结束，不用记着去取消。",
        "账户页会写明到期时间。没有「下期将扣款」这种状态，因为根本不会有下一期，除非你再点一次开通。",
        "这是产品规则，不是优惠活动。之后如果规则变了，会先写在服务条款里，不会悄悄打开自动续费。"
      ],
      bodyEn: [
        "A lot of tools keep people by renewing quietly and hiding the cancel button. 飞连 stops when the term ends.",
        "Short plans only make sense this way. You might need the two weeks you're away, or a few days of a project. When it's over, it's over.",
        "The account page shows the expiry. There is no \"next charge\" state, because there is no next charge unless you start another term.",
        "This is a product rule, not a promotion. If it ever changes, the terms will say so first. Auto-renewal will not appear quietly."
      ]
    },
    {
      id: "travel",
      date: "2026-02-08",
      tagZh: "连接",
      tagEn: "Connection",
      titleZh: "出门之前，把这三件事设好",
      titleEn: "Three things to set before you travel",
      excerptZh: "账号、一台备用设备，还有帮助中心的入口。",
      excerptEn: "Your account, a backup device, and the way back to help.",
      bodyZh: [
        "出发前在家里的网络上登录一次，确认试用或会员还在有效期内。到了酒店再注册，往往会卡在邮件或验证上。",
        "手机和电脑都装好。其中一台连不上时，另一台还能用，也能打开帮助中心。",
        "不要在出发当天换密码。这个演示版没有邮箱找回，正式产品也会建议你在稳定网络里改密码。",
        "到了之后如果酒店门户页（captive portal）先挡住网络，先用普通连接打开门户并完成登录，再打开 飞连。"
      ],
      bodyEn: [
        "Sign in once on your home network and check that the trial or plan is still active. Registering on hotel Wi-Fi often stalls on email or verification.",
        "Install it on both phone and computer. If one cannot connect, the other still can, and can open the help center.",
        "Don't change the password on departure day. This demo has no email recovery, and even a production app is easier to recover on a stable network.",
        "If a hotel captive portal blocks access, finish that page on the normal connection, then open 飞连."
      ]
    }
  ],
  legal: {
    privacy: {
      titleZh: "隐私权政策",
      titleEn: "Privacy policy",
      updated: "2026-10-01",
      sections: [
        { hZh: "我们是谁", hEn: "Who we are", pZh: ["飞连 提供网络连接客户端和这个官网。下面说明官网演示版实际会碰到哪些信息。"], pEn: ["飞连 provides a connection app and this website. This page describes what the demo site actually touches."] },
        { hZh: "账户信息", hEn: "Account data", pZh: ["注册时你填写的名字、邮箱和密码，会保存在这台浏览器的本地存储里。我们用它们完成登录、显示会员到期时间和设备列表。", "密码在保存前会做一次本地摘要，不明文出现在账户页上。这仍然是演示级保护，不是生产环境的密钥体系。"], pEn: ["The name, email, and password you enter are stored in this browser. They are used to sign you in and to show plan expiry and devices.", "The password is stored as a local hash and is not shown back on the account page. That is demo-grade protection, not a production key system."] },
        { hZh: "我们不收集的内容", hEn: "What we don't collect", pZh: ["这个演示站不接收你的浏览记录、DNS 查询或连接目的地，也没有服务器在背后保存它们。", "帮助中心的留言和客服对话同样只留在本机，刷新缓存或换浏览器就会消失。"], pEn: ["This demo does not receive your browsing history, DNS queries, or connection destinations, and no server stores them.", "Help-center messages and the assistant chat stay on this device. Clearing site data or switching browsers removes them."] },
        { hZh: "你的选择", hEn: "Your choices", pZh: ["你可以在账户页删除本机账户，或直接清除浏览器里这个站点的数据。删除后会员、试用和设备列表都会一起消失。"], pEn: ["You can delete the local account on the account page, or clear this site's data in the browser. Plans, trials, and devices go with it."] }
      ]
    },
    terms: {
      titleZh: "服务条款",
      titleEn: "Terms of service",
      updated: "2026-10-01",
      sections: [
        { hZh: "服务是什么", hEn: "The service", pZh: ["飞连 帮助你通过客户端建立加密连接，并在官网管理账户与会员时长。当前这个网站是可交互的产品演示，开通会员不会产生真实扣款。"], pEn: ["飞连 lets the app open an encrypted connection and lets this site manage the account and plan length. This website is an interactive demo. Starting a plan does not charge a real payment."] },
        { hZh: "使用方式", hEn: "Acceptable use", pZh: ["请不要用本服务攻击他人系统、发送垃圾信息或从事违法活动。我们会在正式服务里对滥用的账户做限制。"], pEn: ["Don't use the service to attack other systems, send spam, or break the law. Production accounts that abuse the service can be limited."] },
        { hZh: "会员时长", hEn: "Plan length", pZh: ["时长从你在账户页确认开通时起算，到期自动停止，不会自动续费。试用为 72 小时，和付费会员互不自动转换。"], pEn: ["A plan starts when you confirm it on the account page and stops when it ends. It does not auto-renew. The 72-hour trial does not convert into a paid plan."] },
        { hZh: "责任", hEn: "Liability", pZh: ["演示环境下的连接、下载包和订单号仅用于展示界面。请不要把它当成已经交付的安装程序或已经生效的付费合同。"], pEn: ["Connections, download packages, and order numbers in this demo are here to show the interface. They are not a shipped installer or a paid contract."] }
      ]
    },
    agreement: {
      titleZh: "注册协议",
      titleEn: "Registration agreement",
      updated: "2026-10-01",
      sections: [
        { hZh: "注册", hEn: "Registration", pZh: ["你需要提供可用的邮箱和至少 6 位密码。请使用你愿意放在这台电脑上的信息。演示数据不会上传。"], pEn: ["You need an email and a password of at least 6 characters. Use details you're comfortable keeping on this computer. Demo data is not uploaded."] },
        { hZh: "账户安全", hEn: "Account security", pZh: ["密码只应由你本人使用。在公共设备上用完请退出。你可以从设备列表里移除不再使用的会话。"], pEn: ["Only you should use the password. Sign out on shared devices. You can remove unused sessions from the device list."] },
        { hZh: "试用", hEn: "Trial", pZh: ["每个本机账户可以开始一次 72 小时试用。删除账户再注册，会在这个浏览器里重新计算，这是演示限制，不是可重复领取的活动。"], pEn: ["Each local account can start one 72-hour trial. Deleting the account and registering again restarts it in this browser. That is a demo limitation, not a repeatable offer."] },
        { hZh: "结束", hEn: "Ending it", pZh: ["你可以随时删除本机账户。删除即视为结束这份注册关系在本机上的全部记录。"], pEn: ["You can delete the local account at any time. Deleting it ends every record of this registration on this device."] }
      ]
    }
  },
  chat: [
    { keys: ["试用", "trial", "72"], zh: "注册后试用自动开始，共 72 小时，不用绑支付方式。账户页能看到剩余时间。", en: "The trial starts when you register and lasts 72 hours. No payment method. The account page shows the time left." },
    { keys: ["价格", "会员", "多少钱", "plan", "price", "续费"], zh: "有 7 天、1 个月、3 个月和 12 个月。到期即停，不会自动续费。这里开通是演示，不会扣款。", en: "Terms are 7 days, 1 month, 3 months, and 12 months. They stop when they end and do not auto-renew. Checkout here is a demo and does not charge you." },
    { keys: ["设备", "几台", "device"], zh: "一个账号最多 5 台设备同时在线。可以在账户页移除旧设备。", en: "One account allows five devices online at once. Remove old ones on the account page." },
    { keys: ["下载", "安装", "download", "mac", "windows"], zh: "打开下载页，选中你的系统即可。当前下载的是演示说明文件，不是完整安装包。", en: "Open the download page and pick your system. The file you get now is a demo note, not the full installer." },
    { keys: ["连不上", "失败", "慢", "connect", "slow"], zh: "先换一条延迟更低的线路。如果本地网络本身打不开网页，先解决本地连接，再打开客户端。", en: "Switch to a lower-latency line. If normal pages already fail, fix the local network before opening the app." },
    { keys: ["退款", "扣款", "refund", "pay"], zh: "演示环境没有支付，所以也不存在扣款和退款。正式付款规则会写在服务条款里。", en: "This demo never charges you, so there is nothing to refund. Real payment rules would live in the terms." }
  ]
};
