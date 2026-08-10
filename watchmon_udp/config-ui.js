const express = require("express");
const fs = require("fs");
const path = require("path");

const app = express();
const PORT = 8099;

const DATA_CONFIG = "/data/config.json";
const APP_CONFIG = "/app/config/config.json";
const DIST_CONFIG = "/app/config.json_dist";

app.use(express.urlencoded({ extended: true, limit: "5mb" }));
app.use(express.json({ limit: "5mb" }));

function ensureConfigExists() {
    if (!fs.existsSync(DATA_CONFIG)) {
        if (fs.existsSync(DIST_CONFIG)) {
            fs.copyFileSync(DIST_CONFIG, DATA_CONFIG);
        } else {
            fs.writeFileSync(DATA_CONFIG, "{}");
        }
    }

    fs.mkdirSync(path.dirname(APP_CONFIG), { recursive: true });

    if (!fs.existsSync(APP_CONFIG)) {
        fs.copyFileSync(DATA_CONFIG, APP_CONFIG);
    }
}

function loadConfigText() {
    ensureConfigExists();
    return fs.readFileSync(DATA_CONFIG, "utf8");
}

function saveConfigText(content) {
    const parsed = JSON.parse(content);
    const pretty = JSON.stringify(parsed, null, 4);

    fs.writeFileSync(DATA_CONFIG, pretty);
    fs.mkdirSync(path.dirname(APP_CONFIG), { recursive: true });
    fs.writeFileSync(APP_CONFIG, pretty);

    return pretty;
}

function escapeHtml(value) {
    return String(value)
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;");
}

function renderPage(configText, error, success) {
    const escapedConfig = escapeHtml(configText);

    return `<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <title>Batrium WatchMon UDP Config Editor</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        :root {
            color-scheme: dark;
            --bg: #0f172a;
            --card: #111827;
            --card-soft: #1f2937;
            --text: #e5e7eb;
            --muted: #9ca3af;
            --border: #374151;
            --accent: #38bdf8;
            --accent-hover: #0ea5e9;
            --secondary: #94a3b8;
            --secondary-hover: #cbd5e1;
            --success: #34d399;
        }

        * { box-sizing: border-box; }

        body {
            margin: 0;
            padding: 24px;
            background:
                radial-gradient(circle at top left, rgba(56, 189, 248, 0.12), transparent 32%),
                radial-gradient(circle at bottom right, rgba(52, 211, 153, 0.08), transparent 30%),
                var(--bg);
            color: var(--text);
            font-family: Arial, Helvetica, sans-serif;
        }

        .container { max-width: 1280px; margin: 0 auto; }

        .header {
            background: linear-gradient(135deg, #1e293b, #111827);
            border: 1px solid var(--border);
            border-radius: 18px;
            padding: 22px;
            margin-bottom: 18px;
            box-shadow: 0 14px 40px rgba(0, 0, 0, 0.28);
        }

        .header-top {
            display: flex;
            justify-content: space-between;
            gap: 16px;
            align-items: flex-start;
            flex-wrap: wrap;
        }

        h1 { margin: 0 0 8px 0; font-size: 28px; letter-spacing: -0.02em; }
        .subtitle { color: var(--muted); font-size: 14px; line-height: 1.5; }

        .status-pill {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 8px 12px;
            border-radius: 999px;
            background: rgba(52, 211, 153, 0.12);
            border: 1px solid rgba(52, 211, 153, 0.35);
            color: var(--success);
            font-size: 13px;
            font-weight: 700;
            white-space: nowrap;
        }

        .dot {
            width: 8px;
            height: 8px;
            border-radius: 999px;
            background: var(--success);
            box-shadow: 0 0 12px rgba(52, 211, 153, 0.75);
        }

        .alert {
            border-radius: 14px;
            padding: 13px 15px;
            margin-bottom: 14px;
            font-size: 14px;
            line-height: 1.45;
        }

        .alert.error {
            background: rgba(248, 113, 113, 0.12);
            border: 1px solid rgba(248, 113, 113, 0.45);
            color: #fecaca;
        }

        .alert.success {
            background: rgba(52, 211, 153, 0.12);
            border: 1px solid rgba(52, 211, 153, 0.45);
            color: #bbf7d0;
        }

        .editor-card {
            background: rgba(17, 24, 39, 0.94);
            border: 1px solid var(--border);
            border-radius: 18px;
            padding: 16px;
            box-shadow: 0 14px 40px rgba(0, 0, 0, 0.28);
        }

        textarea {
            width: 100%;
            height: calc(100vh - 340px);
            min-height: 520px;
            resize: vertical;
            background: #020617;
            color: #e5e7eb;
            border: 1px solid var(--border);
            border-radius: 14px;
            padding: 16px;
            font-family: Consolas, Monaco, "Courier New", monospace;
            font-size: 14px;
            line-height: 1.5;
            outline: none;
            tab-size: 4;
        }

        textarea:focus {
            border-color: var(--accent);
            box-shadow: 0 0 0 3px rgba(56, 189, 248, 0.14);
        }

        .actions {
            display: flex;
            gap: 10px;
            margin-top: 14px;
            flex-wrap: wrap;
            align-items: center;
        }

        button {
            border: 0;
            border-radius: 12px;
            padding: 11px 16px;
            cursor: pointer;
            font-weight: 800;
            color: #06111f;
            background: var(--accent);
            transition: background 0.15s ease, transform 0.15s ease;
        }

        button:hover { background: var(--accent-hover); transform: translateY(-1px); }
        button.secondary { background: var(--secondary); }
        button.secondary:hover { background: var(--secondary-hover); }

        .hint { margin-top: 12px; color: var(--muted); font-size: 13px; line-height: 1.45; }

        code {
            background: var(--card-soft);
            color: #dbeafe;
            padding: 2px 6px;
            border-radius: 6px;
            border: 1px solid rgba(148, 163, 184, 0.18);
        }

        .footer-note { margin-top: 12px; color: var(--muted); font-size: 12px; }

        @media (max-width: 720px) {
            body { padding: 14px; }
            h1 { font-size: 22px; }
            textarea { min-height: 460px; height: calc(100vh - 360px); }
            button { width: 100%; }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="header-top">
                <div>
                    <h1>Batrium WatchMon UDP Config Editor</h1>
                    <div class="subtitle">
                        Editing <code>/data/config.json</code>. On save, the config is also copied to
                        <code>/app/config/config.json</code>, which is where the Batrium listener expects it.
                    </div>
                </div>
                <div class="status-pill"><span class="dot"></span>Web UI Online</div>
            </div>
        </div>

        ${error ? `<div class="alert error"><strong>Error:</strong> ${escapeHtml(error)}</div>` : ""}
        ${success ? `<div class="alert success">${escapeHtml(success)}</div>` : ""}

        <div class="editor-card">
            <form method="post" id="configForm">
                <textarea name="config" spellcheck="false">${escapedConfig}</textarea>

                <div class="actions">
                    <button type="submit" formaction="save">Save Config</button>
                    <button type="submit" formaction="format" class="secondary">Format JSON</button>
                    <button type="submit" formaction="reload" class="secondary">Reload From Disk</button>
                </div>

                <div class="hint">
                    JSON is validated before saving. If you change MQTT, InfluxDB, or listener-related settings,
                    restart the app after saving.
                </div>

                <div class="footer-note">
                    Persistent config: <code>/data/config.json</code> |
                    Runtime config: <code>/app/config/config.json</code>
                </div>
            </form>
        </div>
    </div>
</body>
</html>`;
}

app.get("/", (req, res) => {
    let configText = "";
    let error = "";
    let success = "";

    try {
        configText = loadConfigText();
        JSON.parse(configText);
    } catch (err) {
        error = err.message;
    }

    res.send(renderPage(configText, error, success));
});

app.post("/save", (req, res) => {
    const submittedConfig = req.body.config || "";
    let outputConfig = submittedConfig;
    let error = "";
    let success = "";

    try {
        outputConfig = saveConfigText(submittedConfig);
        success = "Config saved successfully. Restart the app for all changes to fully apply.";
    } catch (err) {
        error = err.message;
    }

    res.send(renderPage(outputConfig, error, success));
});

app.post("/format", (req, res) => {
    const submittedConfig = req.body.config || "";
    let outputConfig = submittedConfig;
    let error = "";
    let success = "";

    try {
        outputConfig = JSON.stringify(JSON.parse(submittedConfig), null, 4);
        success = "JSON formatted successfully. Click Save Config to write it to disk.";
    } catch (err) {
        error = err.message;
    }

    res.send(renderPage(outputConfig, error, success));
});

app.post("/reload", (req, res) => {
    let configText = "";
    let error = "";
    let success = "";

    try {
        configText = loadConfigText();
        success = "Config reloaded from disk.";
    } catch (err) {
        error = err.message;
    }

    res.send(renderPage(configText, error, success));
});

app.listen(PORT, "0.0.0.0", () => {
    console.log(`WatchMon config UI listening on port ${PORT}`);
});
