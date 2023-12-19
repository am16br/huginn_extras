$(document).ready(function () {
  const chatContainer = document.getElementById("chat-container");
    const input = document.getElementById("chat-input");
    const messages = document.getElementById("chat-messages");
    const apiKey = "sk-EXm...";
    const conversationHistory = [];
    let chatInitialized = false;

    // Hide the chat container initially
    chatContainer.style.display = "none";

    document.getElementById("submit-button").addEventListener("click", function () {
      sendMessage();
    });

    document.getElementById("close-button").addEventListener("click", function () {
      // Hide the chat container when the close button is clicked
      chatContainer.style.display = 'none';
    });

    input.addEventListener("keydown", (e) => {
      if (e.key === "Enter" && !e.shiftKey) {
        e.preventDefault();
        sendMessage();
      }
    });

    function initializeChat() {
      // System message to initialize the chat
      const systemMessage = "Hi! I am the CIA, your personal chatbot assistant. Ask me anything!";
        messages.innerHTML += `<div class="message bot-message">
          <img src="/assets/chatbot_2.jpg" alt="bot icon" width="50" height="50">
          <span>${systemMessage}</span>
        </div>`;
        conversationHistory.push({ role: 'system', content: systemMessage });
    }

    function sendMessage() {
      const message = input.value.trim();
      if (!message) return;

      input.value = "";

      messages.innerHTML += `<div class="message user-message">
        <img src="/assets/chatbot_1.png" alt="bot icon" width="50" height="50">
        <span>${message}</span>
      </div>`;

      conversationHistory.push({ role: 'user', content: message });

      scrollToBottom(); // Scroll to the bottom after adding a new message

      axios.post(
        'https://api.openai.com/v1/chat/completions',
        {
          model: 'gpt-3.5-turbo',
          messages: conversationHistory,
        },
        {
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${apiKey}`,
          },
        }
      )
      .then((response) => {
        const chatbotResponse = response.data.choices[0].message.content;

        messages.innerHTML += `<div class="message bot-message">
          <img src="/assets/chatbot_2.jpg" alt="bot icon" width="50" height="50">
          <span>${chatbotResponse}</span>
        </div>`;

        conversationHistory.push({ role: 'assistant', content: chatbotResponse });

        scrollToBottom(); // Scroll to the bottom after adding a new message
      })
      .catch((error) => {
        console.error('Error sending message:', error);
      });
    }

    function scrollToBottom() {
      messages.scrollTop = messages.scrollHeight;
    }

    // Show the chat container when the chat icon is clicked
    document.getElementById("chat-icon").addEventListener("click", function () {
      if (!chatInitialized) {
        initializeChat();
        chatInitialized = true;
      }
      chatContainer.style.display = "block";
    });
});
