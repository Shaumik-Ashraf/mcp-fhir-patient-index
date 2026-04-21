import { Controller } from "@hotwired/stimulus"
import { marked } from "marked"

const SESSION_KEY = "chat_config"

const ANTHROPIC_URL = "https://api.anthropic.com/v1/messages"
const ANTHROPIC_VERSION = "2023-06-01"

const DEFAULTS = {
  anthropic: { model: "claude-sonnet-4-6", baseUrl: "" },
  openai:    { model: "gpt-4o",            baseUrl: "https://api.openai.com/v1" },
}

export default class extends Controller {
  static targets = [
    "configPanel", "chatPanel",
    "providerRadio", "baseUrlRow", "baseUrlInput", "apiKeyInput", "modelInput",
    "connectionLabel", "messageList", "messageInput", "sendButton",
  ]

  // Default so this.messages is never undefined, even before #applyConfig()
  // runs (e.g. Turbo cache restoration without a live session).
  messages = []

  // Stimulus lifecycle: element entered the DOM.
  connect() {
    const saved = this.#loadSession()
    if (saved) {
      this.#applyConfig(saved)
      this.#showChat()
    }
  }

  // Stimulus lifecycle: element left the DOM (Turbo navigation, etc.).
  // Do NOT wipe sessionStorage — the user did not explicitly disconnect.
  // Just null out the in-memory API key so it isn't leaked into the cache.
  disconnect() {
    this.apiKey = null
  }

  // ----------------------------------------------------------------
  // Config panel actions
  // ----------------------------------------------------------------

  onProviderChange() {
    const provider = this.#selectedProvider()
    this.baseUrlRowTarget.style.display = provider === "openai" ? "" : "none"
    this.modelInputTarget.placeholder = DEFAULTS[provider].model
    if (provider === "openai" && !this.baseUrlInputTarget.value) {
      this.baseUrlInputTarget.value = DEFAULTS.openai.baseUrl
    }
  }

  onConfigKeydown(e) {
    if (e.key === "Enter") { e.preventDefault(); this.save() }
  }

  save() {
    const provider = this.#selectedProvider()
    const apiKey   = this.apiKeyInputTarget.value.trim()
    const baseUrl  = this.baseUrlInputTarget.value.trim() || DEFAULTS[provider].baseUrl
    const model    = this.modelInputTarget.value.trim()    || DEFAULTS[provider].model

    if (!apiKey) { alert("Please enter an API key."); return }
    if (provider === "openai" && !baseUrl) { alert("Please enter a Base URL."); return }

    this.#applyConfig({ provider, apiKey, baseUrl, model })
    this.#saveSession()
    this.apiKeyInputTarget.value = ""
    this.#showChat()
  }

  // User-initiated disconnect — clears everything including the session.
  // Named differently from the Stimulus lifecycle disconnect() above.
  resetProvider() {
    this.provider = null
    this.apiKey   = null
    this.baseUrl  = null
    this.model    = null
    this.messages = []
    sessionStorage.removeItem(SESSION_KEY)
    this.#showConfig()
  }

  // ----------------------------------------------------------------
  // Chat panel actions
  // ----------------------------------------------------------------

  onMessageKeydown(e) {
    if (e.key === "Enter" && !e.shiftKey) { e.preventDefault(); this.send() }
  }

  async send() {
    const text = this.messageInputTarget.value.trim()
    if (!text) return

    this.messages.push({ role: "user", content: text })
    this.#appendBubble("user", text)
    this.messageInputTarget.value = ""
    this.#setSending(true)

    const assistantBubble = this.#appendBubble("assistant", "")
    const contentEl = assistantBubble.querySelector(".bubble-content")
    let fullText = ""

    try {
      const body = this.#buildBody()
      console.debug("[chat] POST", this.provider, JSON.parse(body))

      const response = await this.#fetchStream(body)

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
        buffer = parts.pop() // keep incomplete chunk

        for (const part of parts) {
          const delta = this.#parseSseDelta(part)
          if (delta) {
            fullText += delta
            contentEl.textContent = fullText
            this.#scrollToBottom()
          }
        }
      }

      // Render final markdown
      contentEl.innerHTML = marked.parse(fullText)
      this.messages.push({ role: "assistant", content: fullText })

    } catch (err) {
      // Roll back the user message so the history stays consistent and the
      // next send doesn't produce back-to-back user messages (which most
      // APIs reject with 400).
      this.messages.pop()
      assistantBubble.remove()
      this.#appendBubble("error", err.message)
    } finally {
      this.#setSending(false)
    }
  }

  // ----------------------------------------------------------------
  // Private helpers
  // ----------------------------------------------------------------

  #selectedProvider() {
    return this.providerRadioTargets.find(r => r.checked)?.value ?? "anthropic"
  }

  #applyConfig({ provider, apiKey, baseUrl, model }) {
    this.provider = provider
    this.apiKey   = apiKey
    this.baseUrl  = baseUrl
    this.model    = model
    this.messages = []

    // Sync radio buttons
    this.providerRadioTargets.forEach(r => { r.checked = r.value === provider })
    this.baseUrlRowTarget.style.display = provider === "openai" ? "" : "none"
    this.baseUrlInputTarget.value = baseUrl || ""
    this.modelInputTarget.placeholder = DEFAULTS[provider]?.model ?? ""
    this.connectionLabelTarget.textContent =
      `${provider === "anthropic" ? "Anthropic" : baseUrl} — ${model}`
  }

  #saveSession() {
    sessionStorage.setItem(SESSION_KEY, JSON.stringify({
      provider: this.provider,
      apiKey:   this.apiKey,
      baseUrl:  this.baseUrl,
      model:    this.model,
    }))
  }

  #loadSession() {
    try {
      const raw = sessionStorage.getItem(SESSION_KEY)
      return raw ? JSON.parse(raw) : null
    } catch { return null }
  }

  #showChat() {
    this.configPanelTarget.style.display = "none"
    this.chatPanelTarget.style.display   = ""
    this.connectionLabelTarget.textContent =
      `${this.provider === "anthropic" ? "Anthropic" : this.baseUrl} — ${this.model}`
    this.messageInputTarget.focus()
  }

  #showConfig() {
    this.chatPanelTarget.style.display   = "none"
    this.configPanelTarget.style.display = ""
    this.messageListTarget.innerHTML     = ""
  }

  #setSending(isSending) {
    this.sendButtonTarget.disabled      = isSending
    this.messageInputTarget.disabled    = isSending
    this.sendButtonTarget.textContent   = isSending ? "…" : "Send"
  }

  #appendBubble(role, text) {
    const wrapper = document.createElement("div")
    wrapper.className = role === "user"
      ? "d-flex justify-content-end mb-2"
      : "d-flex justify-content-start mb-2"

    const bubble = document.createElement("div")
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
      // error
      bubble.className = "card text-bg-danger px-3 py-2 w-100"
      contentEl.textContent = `Error: ${text}`
    }

    bubble.appendChild(contentEl)
    wrapper.appendChild(bubble)
    this.messageListTarget.appendChild(wrapper)
    this.#scrollToBottom()
    return bubble
  }

  #scrollToBottom() {
    const list = this.messageListTarget
    list.scrollTop = list.scrollHeight
  }

  // Serialize the request body for the active provider.
  #buildBody() {
    if (this.provider === "anthropic") {
      return JSON.stringify({
        model:      this.model,
        max_tokens: 1024,
        stream:     true,
        messages:   this.messages,
      })
    } else {
      return JSON.stringify({
        model:    this.model,
        stream:   true,
        messages: this.messages,
      })
    }
  }

  // Fire the streaming fetch request for the active provider.
  async #fetchStream(body) {
    if (this.provider === "anthropic") {
      return fetch(ANTHROPIC_URL, {
        method: "POST",
        headers: {
          "x-api-key":                         this.apiKey,
          "anthropic-version":                 ANTHROPIC_VERSION,
          "content-type":                      "application/json",
          "anthropic-dangerous-allow-browser": "true",
        },
        body,
      })
    } else {
      const url = this.baseUrl.replace(/\/$/, "") + "/chat/completions"
      return fetch(url, {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${this.apiKey}`,
          "content-type":  "application/json",
        },
        body,
      })
    }
  }

  // Extract incremental text from a single SSE event block.
  #parseSseDelta(sseBlock) {
    for (const line of sseBlock.split("\n")) {
      if (!line.startsWith("data:")) continue
      const payload = line.slice(5).trim()
      if (payload === "[DONE]") return null

      let obj
      try { obj = JSON.parse(payload) } catch { continue }

      if (this.provider === "anthropic") {
        if (obj.type === "content_block_delta" && obj.delta?.type === "text_delta") {
          return obj.delta.text
        }
      } else {
        const delta = obj.choices?.[0]?.delta?.content
        if (delta) return delta
      }
    }
    return null
  }
}
