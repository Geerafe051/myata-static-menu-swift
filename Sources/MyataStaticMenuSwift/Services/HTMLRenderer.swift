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
                .page-background { position:fixed; inset:0; z-index:-2; background:linear-gradient(180deg, rgba(8,8,10,.72), rgba(10,10,12,.84)), url("./menu-background.png") center center / cover no-repeat; pointer-events:none; transform:translateZ(0); }
                body.age-gate-locked { overflow:hidden; }
                .site-shell { transition:filter .18s ease, transform .18s ease; }
                body.age-gate-locked .site-shell { filter:blur(16px); transform:scale(1.01); pointer-events:none; user-select:none; }
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
                .age-gate { position:fixed; inset:0; z-index:1000; display:flex; align-items:center; justify-content:center; padding:24px; background:rgba(6,6,8,.58); backdrop-filter:blur(10px); }
                .age-gate[hidden] { display:none; }
                .age-gate-dialog { width:min(100%, 520px); padding:24px; border-radius:24px; border:1px solid rgba(255,255,255,.1); background:linear-gradient(180deg, rgba(24,24,28,.98), rgba(18,18,21,.98)); box-shadow:0 24px 60px rgba(0,0,0,.45); }
                .age-gate-dialog p { margin:0; color:var(--text); font-size:16px; line-height:1.65; }
                .age-gate-actions { display:flex; gap:12px; margin-top:24px; }
                .age-gate-button { flex:1 1 0; min-height:50px; border-radius:16px; border:1px solid var(--border); background:rgba(255,255,255,.04); color:var(--text); font:inherit; font-weight:600; cursor:pointer; }
                .age-gate-button:hover { border-color:rgba(216,166,92,.45); }
                .age-gate-button-primary { background:var(--accent); border-color:rgba(216,166,92,.8); color:#111114; }
                .age-gate-button-primary:hover { border-color:rgba(255,255,255,.5); }
                @media (max-width: 860px) {
                    .grid { grid-template-columns:repeat(2, minmax(0, 1fr)); gap:12px; }
                    .card-top { flex-direction:column; gap:4px; }
                    .card-top h3, .card-top strong { font-size:16px; }
                    .image { aspect-ratio:1/1; padding:8px; }
                    .age-gate-dialog { padding:20px; border-radius:20px; }
                    .age-gate-actions { flex-direction:column; }
                }
            </style>
        </head>
        <body class="age-gate-locked">
            <div class="page-background" aria-hidden="true"></div>
            <div class="site-shell">
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
            </div>
            <div class="age-gate" id="age-gate">
                <div class="age-gate-dialog" id="age-gate-question">
                    <p>В соответствии с требованиями федерального законодательства, мы применяем меры по защите детей от информации, запрещенной для распространения среди них. К такой информации относится и часть содержания данной страницы. Вам есть 18 лет?</p>
                    <div class="age-gate-actions">
                        <button class="age-gate-button age-gate-button-primary" type="button" id="age-gate-yes">Да</button>
                        <button class="age-gate-button" type="button" id="age-gate-no">Еще нет</button>
                    </div>
                </div>
                <div class="age-gate-dialog" id="age-gate-reject" hidden>
                    <p>Мы будем очень ждать, пока вам исполнится 18 лет, а после этого обязательно заходите к нам на страничку!</p>
                    <div class="age-gate-actions">
                        <button class="age-gate-button age-gate-button-primary" type="button" id="age-gate-close">Закрыть сайт</button>
                    </div>
                </div>
            </div>
            <script>
                (function () {
                    var cookieName = "myata_age_verified";
                    var gate = document.getElementById("age-gate");
                    var question = document.getElementById("age-gate-question");
                    var reject = document.getElementById("age-gate-reject");
                    var yesButton = document.getElementById("age-gate-yes");
                    var noButton = document.getElementById("age-gate-no");
                    var closeButton = document.getElementById("age-gate-close");

                    function hasConsent() {
                        return document.cookie.split("; ").some(function (entry) {
                            return entry === cookieName + "=true";
                        });
                    }

                    function unlock() {
                        document.body.classList.remove("age-gate-locked");
                        if (gate) {
                            gate.hidden = true;
                        }
                    }

                    if (hasConsent()) {
                        unlock();
                        return;
                    }

                    if (yesButton) {
                        yesButton.addEventListener("click", function () {
                            document.cookie = cookieName + "=true; Max-Age=31536000; Path=/; SameSite=Lax";
                            unlock();
                        });
                    }

                    if (noButton) {
                        noButton.addEventListener("click", function () {
                            if (question) {
                                question.hidden = true;
                            }
                            if (reject) {
                                reject.hidden = false;
                            }
                        });
                    }

                    if (closeButton) {
                        closeButton.addEventListener("click", function () {
                            window.location.href = "https://ya.ru";
                        });
                    }
                })();
            </script>
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
