package com.cym.study;

import java.util.List;
import java.util.Set;

import org.springframework.ai.chat.client.ChatClient;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;
import tools.jackson.core.JacksonException;

@RestController
public class MaterialSummaryController {
    private static final Set<String> ALLOWED_MATERIALS = Set.of("MAT_A", "MAT_B", "MAT_C");

    private final ChatClient chatClient;
    private final CaseMaterialQuery caseMaterialQuery;

    public MaterialSummaryController(ChatClient.Builder builder, CaseMaterialQuery caseMaterialQuery) {
        this.chatClient = builder.build();
        this.caseMaterialQuery = caseMaterialQuery;
    }

    @GetMapping("/ai/material-summary")
    public MaterialSummary summarize(@RequestParam(name = "caseId", defaultValue = "CASE-001") String caseId) {
        // 先查数据库。案件不存在或不属于当前演示身份时，直接返回 404。
        List<String> providedMaterials = caseMaterialQuery.findProvidedMaterials(caseId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "未找到案件"));
        MaterialSummary result = requestSummary(caseId, providedMaterials);

        // DTO 解析成功后，仍需核对字段和数据库里的案件材料。
        if (result.caseId() == null || result.caseId().isBlank()) {
            throw badModelResponse("模型返回的 caseId 为空");
        }
        if (!caseId.equals(result.caseId())) {
            throw badModelResponse("模型返回的 caseId 与输入不一致");
        }
        if (result.providedMaterials() == null || result.providedMaterials().stream()
                .anyMatch(material -> material == null || !ALLOWED_MATERIALS.contains(material))) {
            throw badModelResponse("模型返回的材料编码无效");
        }
        // 数据库已按材料编码排序。排序后逐项比较可以接受不同顺序，同时识别重复或缺漏。
        if (!providedMaterials.equals(result.providedMaterials().stream().sorted().toList())) {
            throw badModelResponse("模型返回的材料清单与输入不一致");
        }
        if (result.summary() == null || result.summary().isBlank()) {
            throw badModelResponse("模型返回的 summary 为空");
        }

        // 案件编号和材料清单取自查询结果，摘要文字取自模型回复。
        return new MaterialSummary(caseId, providedMaterials, result.summary());
    }

    private MaterialSummary requestSummary(String caseId, List<String> providedMaterials) {
        String input = "案件编号：%s。已提供材料编码列表：%s。".formatted(caseId, providedMaterials);
        String userMessage = input;

        // 首次请求使用原始输入。解析失败时补充格式要求，最多再请求一次。
        for (int attempt = 0; attempt < 2; attempt++) {
            try {
                MaterialSummary result = chatClient.prompt()
                        .system("你是材料整理助手。保留输入的案件编号和材料编码，用一句中文总结已提供的材料。"
                                + "材料列表为空时，返回空数组并说明暂无登记材料。")
                        .user(userMessage)
                        .call()
                        // Spring AI 根据 record 生成格式要求，并将模型回复转换成 Java 对象。
                        .entity(MaterialSummary.class);
                if (result != null) {
                    return result;
                }
            } catch (JacksonException exception) {
                // 模型文本无法转换为 DTO，补充格式要求后重试一次。
            }

            userMessage = input + "上一次输出无法解析。请只返回符合指定结构的 JSON 对象，"
                    + "并将 providedMaterials 写成字符串数组。";
        }

        throw badModelResponse("模型输出无法解析为 MaterialSummary，已尝试修复一次");
    }

    private ResponseStatusException badModelResponse(String detail) {
        return new ResponseStatusException(HttpStatus.BAD_GATEWAY, detail);
    }

    @ExceptionHandler(ResponseStatusException.class)
    ProblemDetail responseError(ResponseStatusException exception) {
        return exception.getBody();
    }
}
