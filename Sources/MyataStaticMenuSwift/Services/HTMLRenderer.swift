import Foundation

enum HTMLRenderer {
    static func render(menuData: MenuData) -> String {
        let navigation = menuData.sections
            .map { "<a class=\"pill\" href=\"#category-\(escape($0.category.id))\">\(escape($0.category.name))</a>" }
            .joined()

        let sections = menuData.sections.map { section in
            let cards = section.items.map { item in
                let description = item.description.isEmpty ? "" : "<p>\(escape(item.description))</p>"
                let image = item.imageURL.isEmpty
                    ? "<div class=\"image placeholder\">MYATA</div>"
                    : "<div class=\"image\"><img src=\"\(escape(item.imageURL))\" alt=\"\(escape(item.name))\"></div>"

                return """
                <article class="card">
                    \(image)
                    <div class="card-body">
                        <div class="card-top">
                            <h3>\(escape(item.name))</h3>
                            <strong>\(formatPrice(item.price)) ₽</strong>
                        </div>
                        \(description)
                    </div>
                </article>
                """
            }.joined()

            return """
            <section class="section" id="category-\(escape(section.category.id))">
                <h2>\(escape(section.category.name))</h2>
                <div class="grid">\(cards)</div>
            </section>
            """
        }.joined()

        let logo = menuData.settings.logoURL.isEmpty ? "" : "<img class=\"logo\" src=\"\(escape(menuData.settings.logoURL))\" alt=\"\(escape(menuData.settings.venueName))\">"
        let favicon = menuData.settings.faviconURL.isEmpty ? "" : "<link rel=\"icon\" href=\"\(escape(menuData.settings.faviconURL))\">"
        let subtitle = menuData.settings.subtitle.isEmpty ? "" : "<p class=\"subtitle\">\(escape(menuData.settings.subtitle))</p>"
        let address = menuData.settings.address.isEmpty ? "" : "<div class=\"meta-row\"><span>Адрес</span><strong>\(escape(menuData.settings.address))</strong></div>"
        let phone = menuData.settings.phone.isEmpty ? "" : "<div class=\"meta-row\"><span>Телефон</span><strong>\(escape(menuData.settings.phone))</strong></div>"
        let instagram = menuData.settings.instagram.isEmpty ? "" : "<div class=\"meta-row\"><span>Instagram</span><strong>\(escape(menuData.settings.instagram))</strong></div>"

        return """
        <!DOCTYPE html>
        <html lang="ru">
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>\(escape(menuData.settings.venueName))</title>
            \(favicon)
            <style>
                :root { color-scheme: dark; --bg:#0a0b0d; --panel:#14181d; --border:#2b3139; --text:#f4f1ea; --muted:#9aa6b2; --accent:#d8a65c; }
                * { box-sizing:border-box; } html { scroll-behavior:smooth; }
                body { margin:0; font-family:-apple-system,BlinkMacSystemFont,"SF Pro Display",sans-serif; background:linear-gradient(180deg,#090b0e,#10151b 50%,#090b0e); color:var(--text); }
                .shell { width:min(1180px, calc(100% - 24px)); margin:0 auto; }
                .hero { padding:16px 0 12px; }
                .hero-panel { display:grid; grid-template-columns:auto 1fr; gap:14px; align-items:center; padding:14px 16px; background:rgba(20,24,29,.95); border:1px solid var(--border); border-radius:22px; }
                .logo { width:72px; height:72px; object-fit:contain; border-radius:18px; padding:8px; background:rgba(255,255,255,.03); border:1px solid rgba(255,255,255,.08); }
                h1 { margin:0; font-size:34px; }
                .subtitle { margin:0 0 6px; font-size:11px; letter-spacing:.22em; text-transform:uppercase; color:var(--accent); }
                .meta { display:grid; gap:8px; margin-top:12px; }
                .meta-row { display:flex; justify-content:space-between; gap:12px; padding:10px 12px; border-radius:14px; background:rgba(255,255,255,.03); border:1px solid var(--border); font-size:14px; }
                .meta-row span { color:var(--muted); }
                .rail { position:sticky; top:0; z-index:20; backdrop-filter:blur(14px); background:rgba(10,11,13,.84); border-top:1px solid rgba(255,255,255,.05); border-bottom:1px solid rgba(255,255,255,.08); }
                .rail-inner { display:flex; gap:10px; overflow:auto; padding:14px 0; }
                .pill { flex:0 0 auto; color:var(--text); text-decoration:none; padding:11px 16px; border-radius:999px; border:1px solid var(--border); background:rgba(255,255,255,.03); }
                .main { padding:24px 0 64px; }
                .section + .section { margin-top:52px; }
                .section h2 { margin:0 0 18px; font-size:34px; }
                .grid { display:grid; grid-template-columns:repeat(3, minmax(0, 1fr)); gap:18px; }
                .card { overflow:hidden; border-radius:26px; background:rgba(20,24,29,.94); border:1px solid var(--border); }
                .image { aspect-ratio:4/3; display:grid; place-items:center; padding:10px; background:linear-gradient(135deg, rgba(216,166,92,.18), rgba(255,255,255,.04)); }
                .image img { width:100%; height:100%; object-fit:contain; border-radius:18px; }
                .placeholder { letter-spacing:.34em; font-weight:700; color:rgba(255,255,255,.66); }
                .card-body { padding:14px; }
                .card-top { display:flex; justify-content:space-between; gap:12px; align-items:baseline; }
                .card-top h3, .card-top strong { margin:0; font-size:20px; }
                .card-top strong { color:var(--accent); white-space:nowrap; }
                .card p { margin:10px 0 0; color:var(--muted); line-height:1.5; font-size:14px; }
                @media (max-width: 860px) {
                    .grid { grid-template-columns:repeat(2, minmax(0, 1fr)); gap:12px; }
                    .card-top { flex-direction:column; gap:4px; }
                    .card-top h3, .card-top strong { font-size:16px; }
                    .image { aspect-ratio:1/1; padding:8px; }
                }
            </style>
        </head>
        <body>
            <header class="hero">
                <div class="shell hero-panel">
                    \(logo)
                    <div>
                        \(subtitle)
                        <h1>\(escape(menuData.settings.venueName))</h1>
                        <div class="meta">\(address)\(phone)\(instagram)</div>
                    </div>
                </div>
            </header>
            <div class="rail">
                <div class="shell rail-inner">\(navigation)</div>
            </div>
            <main class="shell main">\(sections)</main>
        </body>
        </html>
        """
    }

    private static func escape(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }

    private static func formatPrice(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
