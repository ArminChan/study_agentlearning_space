package com.cym.study;


import org.springframework.ai.chat.client.ChatClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class ChatController {
    private final ChatClient chatClient;

    public ChatController(ChatClient.Builder builder) {
        this.chatClient = builder.build();
    }

    @GetMapping("/ai/chat")
    public String chat(@RequestParam(name = "message",
            defaultValue = "只回复：学习环境已连接") String message) {
        return chatClient.prompt().user(message).call().content();
    }

    @GetMapping("/ai/chat2") 
    public String chat2(@RequestParam(name = "message",
            defaultValue = "只回复：学习环境已连接") String message) {

        return chatClient.prompt()
                .system("你是学习助手，只用一句中文回答，不编造输入中没有的材料。")
                .user(message)
                .call().content();

    }
}