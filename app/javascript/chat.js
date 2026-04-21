import { marked } from "marked"

const SESSION_KEY = "chat_config"

const ANTHROPIC_URL     = "https://api.anthropic.com/v1/messages"
const ANTHROPIC_VERSION = "2023-06-01"

const DEFAULTS = {
  anthropic: { model: "claude-sonnet-4-6",  baseUrl: "" },
  openai:    { model: "gpt-4o",             baseUrl: "https://api.openai.com/v1" },
  lmstudio:  { model: "local-model",        baseUrl: "http://localhost:1234/v1" },
}

// Module-level state — persists across Turbo navigations within the session.
let provider, apiKey, baseUrl, model
let messages = []

// DOM references — re-grabbed on every init() call so they're always fresh.
let configPanel, chatPanel, providerRadios, baseUrlRow, baseUrlInput,
    apiKeyRow, apiKeyInput, modelInput, connectionLabel,
    messageList, messageInput, sendBtn

// -----------------------------------------------------------------------
// Bootstrap — fires on initial page load and on every Turbo navigation.
// The guard at the top makes it a no-op on every page except /chat.
// -----------------------------------------------------------------------

function init() {
  if (!document.getElementById("chat-config-panel")) return

  // Grab all DOM refs once
  configPanel      = document.getElementById("chat-config-panel")
  chatPanel        = document.getElementById("chat-panel")
  providerRadios   = document.querySelectorAll('input[name="chat-provider"]')
  baseUrlRow       = document.getElementById("chat-base-url-row")
  baseUrlInput     = document.getElementById("chat-base-url")
  apiKeyRow        = document.getElementById("chat-api-key-row")
  apiKeyInput      = document.getElementById("chat-api-key")
  modelInput       = document.getElementById("chat-model")
  connectionLabel  = document.getElementById("chat-connection-label")
  messageList      = document.getElementById("chat-message-list")
  messageInput     = document.getElementById("chat-message-input")
  sendBtn          = document.getElementById("chat-send-btn")
  const connectBtn    = document.getElementById("chat-connect-btn")
  const disconnectBtn = document.getElementById("chat-disconnect-btn")

  // Wire event listeners
  providerRadios.forEach(r => r.addEventListener("change", onProviderChange))
  apiKeyInput.addEventListener("keydown", onConfigKeydown)
  modelInput.addEventListener("keydown", onConfigKeydown)
  connectBtn.addEventListener("click", save)
  disconnectBtn.addEventListener("click", resetProvider)
  sendBtn.addEventListener("click", send)
  messageInput.addEventListener("keydown", onMessageKeydown)

  // Restore session or show config
  const saved = loadSession()
  if (saved) {
    applyConfig(saved)
    showChat()
  }
}

document.addEventListener("DOMContentLoaded", init)
document.addEventListener("turbo:load", init)

// -----------------------------------------------------------------------
// Config panel
// -----------------------------------------------------------------------

function onProviderChange() {
  const p = selectedProvider()
  const needsBaseUrl = (p === "openai" || p === "lmstudio")
  const needsKey     = (p !== "lmstudio")

  baseUrlRow.style.display  = needsBaseUrl ? "" : "none"
  apiKeyRow.style.display   = needsKey     ? "" : "none"
  modelInput.placeholder    = DEFAULTS[p].model

  if (needsBaseUrl && !baseUrlInput.value) {
    baseUrlInput.value = DEFAULTS[p].baseUrl
  }
}

function onConfigKeydown(e) {
  if (e.key === "Enter") { e.preventDefault(); save() }
}

function save() {
  const p      = selectedProvider()
  const key    = apiKeyInput.value.trim()
  const url    = baseUrlInput.value.trim() || DEFAULTS[p].baseUrl
  const mdl    = modelInput.value.trim()   || DEFAULTS[p].model

  if (p !== "lmstudio" && !key) { alert("Please enter an API key."); return }
  if ((p === "openai" || p === "lmstudio") && !url) { alert("Please enter a Base URL."); return }

  applyConfig({ provider: p, apiKey: key, baseUrl: url, model: mdl })
  saveSession()
  apiKeyInput.value = ""
  showChat()
}

function resetProvider() {
  provider = null; apiKey = null; baseUrl = null; model = null
  messages = []
  sessionStorage.removeItem(SESSION_KEY)
  showConfig()
}

// -----------------------------------------------------------------------
// Chat panel
// -----------------------------------------------------------------------

function onMessageKeydown(e) {
  if (e.key === "Enter" && !e.shiftKey) { e.preventDefault(); send() }
}

async function send() {
  const text = messageInput.value.trim()
  if (!text) return

  messages.push({ role: "user", content: text })
  appendBubble("user", text)
  messageInput.value = ""
  setSending(true)

  const assistantBubble = appendBubble("assistant", "")
  const contentEl = assistantBubble.querySelector(".bubble-content")
  let fullText = ""

  try {
    const body = buildBody()
    console.debug("[chat] POST", provider, JSON.parse(body))

    const response = await fetchStream(body)

    if (!response.ok) {
      const errBody = await response.text()
      console.error("[chat] API error", response.status, errBody)
      throw new Error(`HTTP ${response.status}: ${errBody}`)
    }

    const reader  = response.body.getReader()
    const decoder = new TextDecoder()
    let buffer = ""

    while (true) {
      const { done, value } = await reader.read()
      if (done) break

      buffer += decoder.decode(value, { stream: true })
      const parts = buffer.split("\n\n")
      buffer = parts.pop() // keep incomplete trailing chunk

      for (const part of parts) {
        const delta = parseSseDelta(part)
        if (delta) {
          fullText += delta
          contentEl.textContent = fullText
          scrollToBottom()
        }
      }
    }

    contentEl.innerHTML = marked.parse(fullText)
    messages.push({ role: "assistant", content: fullText })

  } catch (err) {
    // Roll back user message — prevents back-to-back user msgs on retry
    // (both Anthropic and OpenAI-compatible APIs reject that with 400).
    messages.pop()
    assistantBubble.remove()
    appendBubble("error", err.message)
  } finally {
    setSending(false)
  }
}

// -----------------------------------------------------------------------
// Private helpers
// -----------------------------------------------------------------------

function selectedProvider() {
  for (const r of providerRadios) { if (r.checked) return r.value }
  return "anthropic"
}

function applyConfig(cfg) {
  provider = cfg.provider
  apiKey   = cfg.apiKey
  baseUrl  = cfg.baseUrl
  model    = cfg.model
  messages = []

  // Sync radio buttons
  providerRadios.forEach(r => { r.checked = r.value === provider })

  const needsBaseUrl = (provider === "openai" || provider === "lmstudio")
  const needsKey     = (provider !== "lmstudio")
  baseUrlRow.style.display = needsBaseUrl ? "" : "none"
  apiKeyRow.style.display  = needsKey     ? "" : "none"
  baseUrlInput.value = cfg.baseUrl || ""
  modelInput.placeholder = DEFAULTS[provider]?.model ?? ""
  connectionLabel.textContent = connectionText()
}

function connectionText() {
  if (provider === "anthropic") return `Anthropic — ${model}`
  if (provider === "lmstudio")  return `LM Studio (${baseUrl}) — ${model}`
  return `${baseUrl} — ${model}`
}

function saveSession() {
  sessionStorage.setItem(SESSION_KEY, JSON.stringify({ provider, apiKey, baseUrl, model }))
}

function loadSession() {
  try {
    const raw = sessionStorage.getItem(SESSION_KEY)
    return raw ? JSON.parse(raw) : null
  } catch { return null }
}

function showChat() {
  configPanel.style.display = "none"
  chatPanel.style.display   = ""
  connectionLabel.textContent = connectionText()
  messageInput.focus()
}

function showConfig() {
  chatPanel.style.display   = "none"
  configPanel.style.display = ""
  messageList.innerHTML     = ""
}

function setSending(isSending) {
  sendBtn.disabled       = isSending
  messageInput.disabled  = isSending
  sendBtn.textContent    = isSending ? "…" : "Send"
}

function appendBubble(role, text) {
  const wrapper = document.createElement("div")
  wrapper.className = role === "user"
    ? "d-flex justify-content-end mb-2"
    : "d-flex justify-content-start mb-2"

  const bubble    = document.createElement("div")
  const contentEl = document.createElement("div")
  contentEl.className = "bubble-content"

  if (role === "user") {
    bubble.className = "card text-bg-primary px-3 py-2"
    bubble.style.maxWidth = "75%"
    contentEl.textContent = text
  } else if (role === "assistant") {
    bubble.className = "card px-3 py-2"
    bubble.style.maxWidth = "85%"
    contentEl.innerHTML = text ? marked.parse(text) : ""
  } else {
    bubble.className = "card text-bg-danger px-3 py-2 w-100"
    contentEl.textContent = `Error: ${text}`
  }

  bubble.appendChild(contentEl)
  wrapper.appendChild(bubble)
  messageList.appendChild(wrapper)
  scrollToBottom()
  return bubble
}

function scrollToBottom() {
  messageList.scrollTop = messageList.scrollHeight
}

function buildBody() {
  if (provider === "anthropic") {
    return JSON.stringify({
      model:      model,
      max_tokens: 1024,
      stream:     true,
      messages:   messages,
    })
  }
  // openai + lmstudio share the same request shape
  return JSON.stringify({
    model:    model,
    stream:   true,
    messages: messages,
  })
}

async function fetchStream(body) {
  if (provider === "anthropic") {
    return fetch(ANTHROPIC_URL, {
      method: "POST",
      headers: {
        "x-api-key":                         apiKey,
        "anthropic-version":                 ANTHROPIC_VERSION,
        "content-type":                      "application/json",
        "anthropic-dangerous-allow-browser": "true",
      },
      body,
    })
  }

  if (provider === "openai") {
    const url = baseUrl.replace(/\/$/, "") + "/chat/completions"
    return fetch(url, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${apiKey}`,
        "content-type":  "application/json",
      },
      body,
    })
  }

  // lmstudio — no Authorization header (its CORS policy rejects it)
  const url = baseUrl.replace(/\/$/, "") + "/chat/completions"
  return fetch(url, {
    method: "POST",
    headers: {
      "content-type": "application/json",
    },
    body,
  })
}

function parseSseDelta(sseBlock) {
  for (const line of sseBlock.split("\n")) {
    if (!line.startsWith("data:")) continue
    const payload = line.slice(5).trim()
    if (payload === "[DONE]") return null

    let obj
    try { obj = JSON.parse(payload) } catch { continue }

    if (provider === "anthropic") {
      if (obj.type === "content_block_delta" && obj.delta?.type === "text_delta") {
        return obj.delta.text
      }
    } else {
      // openai + lmstudio share the same SSE format
      const delta = obj.choices?.[0]?.delta?.content
      if (delta) return delta
    }
  }
  return null
}
