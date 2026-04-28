import Foundation

enum HTMLRenderer {
    static func render(menuData: MenuData) -> String {
        let navigation = menuData.sections
            .map { "<a class=\"pill\" href=\"#category-\(escape($0.category.id))\" data-category-link=\"category-\(escape($0.category.id))\">\(escape($0.category.name))</a>" }
            .joined()

        let sections = menuData.sections.map { section in
            let cards = section.items.map { item in
                let image = item.imageURL.isEmpty
                    ? "<div class=\"image placeholder\">MYATA</div>"
                    : "<div class=\"image\"><img src=\"\(escape(item.imageURL))\" alt=\"\(escape(item.name))\"></div>"

                return """
                <article class="card" role="button" tabindex="0"
                    data-item-name="\(escape(item.name))"
                    data-item-price="\(formatPrice(item.price)) ₽"
                    data-item-description="\(escape(item.description))"
                    data-item-image="\(escape(item.imageURL))"
                    data-item-portion="\(escape(item.portion))"
                    data-item-calories="\(escape(item.calories))"
                    data-item-proteins="\(escape(item.proteins))"
                    data-item-fats="\(escape(item.fats))"
                    data-item-carbohydrates="\(escape(item.carbohydrates))"
                    data-item-show-nf="\(item.showNutritionFacts ? "true" : "false")">
                    \(image)
                    <div class="card-body">
                        <div class="card-top">
                            <h3>\(escape(item.name))</h3>
                            <strong>\(formatPrice(item.price)) ₽</strong>
                        </div>
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
                :root { color-scheme: dark; --bg:#0a0b0d; --panel:#14181d; --border:#2b3139; --text:#f4f1ea; --muted:#9aa6b2; --accent:#d8a65c; --active-green:#123f2b; --active-green-border:#2a7a52; }
                * { box-sizing:border-box; } html { scroll-behavior:smooth; }
                body { margin:0; font-family:-apple-system,BlinkMacSystemFont,"SF Pro Display",sans-serif; background:linear-gradient(180deg,#090b0e,#10151b 50%,#090b0e); color:var(--text); }
                .page-background { position:fixed; inset:0; z-index:-2; background:linear-gradient(180deg, rgba(8,8,10,.72), rgba(10,10,12,.84)), url("./menu-background.png") center center / cover no-repeat; pointer-events:none; transform:translateZ(0); }
                body.age-gate-locked { overflow:hidden; }
                body.item-modal-open { overflow:hidden; }
                .site-shell { transition:filter .18s ease, transform .18s ease; }
                body.age-gate-locked .site-shell { filter:blur(16px); transform:scale(1.01); pointer-events:none; user-select:none; }
                body.item-modal-open .site-shell { filter:blur(10px); pointer-events:none; user-select:none; }
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
                .pill { flex:0 0 auto; color:var(--text); text-decoration:none; padding:11px 16px; border-radius:999px; border:1px solid var(--border); background:rgba(255,255,255,.03); transition:background .18s ease, border-color .18s ease, color .18s ease, transform .18s ease; }
                .pill:hover { border-color:rgba(42,122,82,.68); background:rgba(18,63,43,.48); }
                .pill.active { background:linear-gradient(180deg, rgba(28,86,59,.94), rgba(14,50,34,.94)); border-color:var(--active-green-border); color:#f5fff8; box-shadow:0 8px 24px rgba(0,0,0,.18); }
                .main { padding:24px 0 64px; }
                .section + .section { margin-top:52px; }
                .section { scroll-margin-top:110px; }
                .section h2 { margin:0 0 18px; font-size:34px; font-weight:500; letter-spacing:-.02em; }
                .grid { display:grid; grid-template-columns:repeat(3, minmax(0, 1fr)); gap:18px; }
                .card { overflow:hidden; border-radius:26px; background:rgba(20,24,29,.94); border:1px solid var(--border); cursor:pointer; transition:transform .16s ease, border-color .16s ease, background .16s ease; }
                .card:hover { transform:translateY(-2px); border-color:rgba(216,166,92,.36); background:rgba(24,28,33,.96); }
                .card:focus-visible { outline:2px solid rgba(216,166,92,.72); outline-offset:3px; }
                .image { aspect-ratio:4/3; display:grid; place-items:center; padding:10px; background:linear-gradient(135deg, rgba(216,166,92,.18), rgba(255,255,255,.04)); }
                .image img { width:100%; height:100%; object-fit:contain; border-radius:18px; }
                .placeholder { letter-spacing:.34em; font-weight:700; color:rgba(255,255,255,.66); }
                .card-body { padding:14px; }
                .card-top { display:flex; justify-content:space-between; gap:12px; align-items:baseline; }
                .card-top h3, .card-top strong { margin:0; font-size:20px; font-weight:500; letter-spacing:-.01em; }
                .card-top strong { color:var(--accent); white-space:nowrap; }
                .card p { margin:10px 0 0; color:var(--muted); line-height:1.5; font-size:14px; }
                .item-modal { position:fixed; inset:0; z-index:900; display:flex; align-items:center; justify-content:center; padding:22px; background:rgba(4,4,6,.62); backdrop-filter:blur(14px); }
                .item-modal[hidden] { display:none; }
                .item-modal-dialog { position:relative; width:min(100%, 1120px); min-height:540px; display:grid; grid-template-columns:minmax(320px, 1.05fr) minmax(360px, .95fr); overflow:hidden; border-radius:32px; border:1px solid rgba(255,255,255,.08); background:linear-gradient(135deg, rgba(3,4,5,.96), rgba(23,24,26,.96)); box-shadow:0 28px 90px rgba(0,0,0,.62); }
                .item-modal-media { display:grid; place-items:center; min-height:540px; padding:42px; background:radial-gradient(circle at center, rgba(216,166,92,.12), transparent 42%), rgba(0,0,0,.44); }
                .item-modal-media img { width:100%; height:100%; max-height:500px; object-fit:contain; border-radius:24px; }
                .item-modal-placeholder { width:100%; min-height:360px; display:grid; place-items:center; border-radius:24px; background:rgba(255,255,255,.04); color:rgba(255,255,255,.5); letter-spacing:.34em; }
                .item-modal-content { display:flex; flex-direction:column; gap:24px; padding:44px 48px 48px; }
                .item-modal-title { margin:0; font-size:34px; font-weight:500; letter-spacing:-.025em; }
                .nutrition-grid { display:grid; grid-template-columns:repeat(5, minmax(0, 1fr)); gap:0; color:var(--muted); }
                .nutrition-grid[hidden] { display:none; }
                .nutrition-cell { min-width:0; padding:0 14px 0 0; border-right:1px solid rgba(255,255,255,.12); }
                .nutrition-cell:last-child { border-right:0; }
                .nutrition-label { display:block; font-size:18px; line-height:1.15; color:rgba(244,241,234,.52); }
                .nutrition-value { display:block; margin-top:4px; font-size:18px; color:rgba(244,241,234,.72); }
                .item-modal-description { margin:0; max-width:640px; color:rgba(244,241,234,.58); font-size:20px; line-height:1.45; letter-spacing:.02em; }
                .item-modal-price { margin-top:auto; min-height:64px; display:flex; align-items:center; justify-content:center; border-radius:20px; background:rgba(255,255,255,.08); color:var(--text); font-size:28px; font-weight:500; }
                .item-modal-close { position:absolute; top:18px; right:20px; width:44px; height:44px; display:grid; place-items:center; border:0; background:transparent; color:rgba(255,255,255,.42); font-size:42px; line-height:1; cursor:pointer; }
                .item-modal-close:hover { color:rgba(255,255,255,.78); }
                .item-modal-back { display:none; align-self:flex-start; border:0; background:transparent; color:var(--text); font:inherit; font-weight:500; padding:0; cursor:pointer; }
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
                    .item-modal { align-items:stretch; padding:0; background:rgba(8,8,10,.92); }
                    .item-modal-dialog { width:100%; min-height:100dvh; border-radius:0; border:0; grid-template-columns:1fr; overflow:auto; }
                    .item-modal-media { min-height:38dvh; padding:22px 22px 8px; }
                    .item-modal-media img { max-height:36dvh; border-radius:18px; }
                    .item-modal-placeholder { min-height:28dvh; }
                    .item-modal-content { padding:18px 20px 28px; gap:18px; }
                    .item-modal-title { font-size:28px; }
                    .nutrition-grid { grid-template-columns:repeat(2, minmax(0, 1fr)); gap:12px 0; }
                    .nutrition-cell { border-right:0; padding:0; }
                    .nutrition-label, .nutrition-value { font-size:16px; }
                    .item-modal-description { font-size:16px; }
                    .item-modal-price { min-height:56px; font-size:24px; }
                    .item-modal-close { display:none; }
                    .item-modal-back { display:inline-flex; }
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
            <div class="item-modal" id="item-modal" hidden>
                <article class="item-modal-dialog" role="dialog" aria-modal="true" aria-labelledby="item-modal-title">
                    <button class="item-modal-close" type="button" id="item-modal-close" aria-label="Закрыть" title="Закрыть">×</button>
                    <div class="item-modal-media" id="item-modal-media"></div>
                    <div class="item-modal-content">
                        <button class="item-modal-back" type="button" id="item-modal-back">← Назад</button>
                        <h2 class="item-modal-title" id="item-modal-title"></h2>
                        <div class="nutrition-grid" aria-label="КБЖУ на порцию">
                            <div class="nutrition-cell">
                                <span class="nutrition-label">Порция</span>
                                <span class="nutrition-value" id="item-modal-portion">—</span>
                            </div>
                            <div class="nutrition-cell">
                                <span class="nutrition-label">Ккал</span>
                                <span class="nutrition-value" id="item-modal-calories">—</span>
                            </div>
                            <div class="nutrition-cell">
                                <span class="nutrition-label">Белки</span>
                                <span class="nutrition-value" id="item-modal-proteins">—</span>
                            </div>
                            <div class="nutrition-cell">
                                <span class="nutrition-label">Жиры</span>
                                <span class="nutrition-value" id="item-modal-fats">—</span>
                            </div>
                            <div class="nutrition-cell">
                                <span class="nutrition-label">Углеводы</span>
                                <span class="nutrition-value" id="item-modal-carbohydrates">—</span>
                            </div>
                        </div>
                        <p class="item-modal-description" id="item-modal-description"></p>
                        <div class="item-modal-price" id="item-modal-price"></div>
                    </div>
                </article>
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

                (function () {
                    var modal = document.getElementById("item-modal");
                    var media = document.getElementById("item-modal-media");
                    var title = document.getElementById("item-modal-title");
                    var description = document.getElementById("item-modal-description");
                    var price = document.getElementById("item-modal-price");
                    var nutritionGrid = document.querySelector(".nutrition-grid");
                    var closeButton = document.getElementById("item-modal-close");
                    var backButton = document.getElementById("item-modal-back");
                    var fields = {
                        portion: document.getElementById("item-modal-portion"),
                        calories: document.getElementById("item-modal-calories"),
                        proteins: document.getElementById("item-modal-proteins"),
                        fats: document.getElementById("item-modal-fats"),
                        carbohydrates: document.getElementById("item-modal-carbohydrates")
                    };

                    function valueOrDash(value) {
                        return value && value.trim() ? value.trim() : "—";
                    }

                    function openModal(card) {
                        if (!modal || !media || !title || !description || !price) {
                            return;
                        }

                        var imageURL = card.dataset.itemImage || "";
                        media.innerHTML = imageURL
                            ? '<img src="' + imageURL.replace(/"/g, "&quot;") + '" alt="">'
                            : '<div class="item-modal-placeholder">MYATA</div>';

                        title.textContent = card.dataset.itemName || "";
                        description.textContent = card.dataset.itemDescription || "";
                        description.hidden = !description.textContent.trim();
                        price.textContent = card.dataset.itemPrice || "";

                        var showNutritionFacts = (card.dataset.itemShowNf || "").toLowerCase() === "true";
                        if (nutritionGrid) {
                            nutritionGrid.hidden = !showNutritionFacts;
                        }

                        if (showNutritionFacts) {
                            fields.portion.textContent = valueOrDash(card.dataset.itemPortion);
                            fields.calories.textContent = valueOrDash(card.dataset.itemCalories);
                            fields.proteins.textContent = valueOrDash(card.dataset.itemProteins);
                            fields.fats.textContent = valueOrDash(card.dataset.itemFats);
                            fields.carbohydrates.textContent = valueOrDash(card.dataset.itemCarbohydrates);
                        }

                        modal.hidden = false;
                        document.body.classList.add("item-modal-open");
                    }

                    function closeModal() {
                        if (!modal) {
                            return;
                        }

                        modal.hidden = true;
                        document.body.classList.remove("item-modal-open");
                    }

                    document.querySelectorAll(".card").forEach(function (card) {
                        card.addEventListener("click", function () {
                            openModal(card);
                        });

                        card.addEventListener("keydown", function (event) {
                            if (event.key === "Enter" || event.key === " ") {
                                event.preventDefault();
                                openModal(card);
                            }
                        });
                    });

                    if (closeButton) {
                        closeButton.addEventListener("click", closeModal);
                    }

                    if (backButton) {
                        backButton.addEventListener("click", closeModal);
                    }

                    if (modal) {
                        modal.addEventListener("click", function (event) {
                            if (event.target === modal) {
                                closeModal();
                            }
                        });
                    }

                    document.addEventListener("keydown", function (event) {
                        if (event.key === "Escape" && modal && !modal.hidden) {
                            closeModal();
                        }
                    });
                })();

                (function () {
                    var links = Array.prototype.slice.call(document.querySelectorAll("[data-category-link]"));
                    var sections = links
                        .map(function (link) {
                            return document.getElementById(link.dataset.categoryLink);
                        })
                        .filter(Boolean);

                    if (!links.length || !sections.length) {
                        return;
                    }

                    function setActive(sectionId) {
                        links.forEach(function (link) {
                            var isActive = link.dataset.categoryLink === sectionId;
                            link.classList.toggle("active", isActive);
                            if (isActive) {
                                link.scrollIntoView({ behavior: "smooth", inline: "center", block: "nearest" });
                            }
                        });
                    }

                    function updateActiveFromScroll() {
                        var anchor = window.scrollY + 130;
                        var current = sections[0];

                        sections.forEach(function (section) {
                            if (section.offsetTop <= anchor) {
                                current = section;
                            }
                        });

                        if (current) {
                            setActive(current.id);
                        }
                    }

                    links.forEach(function (link) {
                        link.addEventListener("click", function (event) {
                            event.preventDefault();

                            var sectionId = link.dataset.categoryLink;
                            var targetSection = sectionId ? document.getElementById(sectionId) : null;
                            if (targetSection) {
                                targetSection.scrollIntoView({ behavior: "smooth", block: "start" });
                                if (window.history && window.history.replaceState) {
                                    window.history.replaceState(null, "", "#" + sectionId);
                                } else {
                                    window.location.hash = sectionId;
                                }
                            }

                            setActive(sectionId);
                        });
                    });

                    var ticking = false;
                    window.addEventListener("scroll", function () {
                        if (ticking) {
                            return;
                        }

                        ticking = true;
                        window.requestAnimationFrame(function () {
                            updateActiveFromScroll();
                            ticking = false;
                        });
                    }, { passive: true });

                    window.addEventListener("resize", updateActiveFromScroll);
                    updateActiveFromScroll();
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
