package com.cym.study;

import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.mockito.ArgumentCaptor;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.messages.AssistantMessage;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.chat.model.ChatResponse;
import org.springframework.ai.chat.model.Generation;
import org.springframework.ai.chat.prompt.ChatOptions;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class MaterialSummaryControllerTest {
    private static final String ENDPOINT = "/ai/material-summary";
    private static final String VALID_JSON = """
            {"caseId":"CASE-001","providedMaterials":["MAT_A"],"summary":"已提供 MAT_A。"}
            """;

    private ChatModel model;
    private CaseMaterialQuery caseMaterialQuery;
    private MockMvc mvc;

    @BeforeEach
    void setUp() {
        model = mock(ChatModel.class);
        when(model.getOptions()).thenReturn(ChatOptions.builder().build());
        caseMaterialQuery = mock(CaseMaterialQuery.class);
        when(caseMaterialQuery.findProvidedMaterials("CASE-001")).thenReturn(Optional.of(List.of("MAT_A")));
        mvc = MockMvcBuilders.standaloneSetup(
                new MaterialSummaryController(ChatClient.builder(model), caseMaterialQuery)).build();
    }

    @Test
    void returnsTypedResultAsHttpJson() throws Exception {
        when(model.call(any(Prompt.class))).thenReturn(reply(VALID_JSON));

        mvc.perform(get(ENDPOINT))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.caseId").value("CASE-001"))
                .andExpect(jsonPath("$.providedMaterials[0]").value("MAT_A"))
                .andExpect(jsonPath("$.providedMaterials.length()").value(1))
                .andExpect(jsonPath("$.summary").value("已提供 MAT_A。"));

        verify(model).call(any(Prompt.class));
    }

    @ParameterizedTest
    @CsvSource({
            "'',       MAT_A, 模型返回的 caseId 为空",
            "CASE-001, MAT_X, 模型返回的材料编码无效",
            "CASE-001, MAT_B, 模型返回的材料清单与输入不一致"
    })
    void rejectsInvalidFieldsWithoutRepair(String caseId, String material, String detail) throws Exception {
        String json = """
                {"caseId":"%s","providedMaterials":["%s"],"summary":"材料摘要。"}
                """.formatted(caseId, material);
        when(model.call(any(Prompt.class))).thenReturn(reply(json));

        mvc.perform(get(ENDPOINT))
                .andExpect(status().isBadGateway())
                .andExpect(jsonPath("$.detail").value(detail));

        verify(model).call(any(Prompt.class));
    }

    @Test
    void repairsMalformedJsonOnce() throws Exception {
        when(model.call(any(Prompt.class))).thenReturn(reply("{"), reply(VALID_JSON));

        mvc.perform(get(ENDPOINT))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.caseId").value("CASE-001"));

        var prompts = ArgumentCaptor.forClass(Prompt.class);
        verify(model, times(2)).call(prompts.capture());
        assertThat(prompts.getValue().getUserMessage().getText()).contains("CASE-001", "MAT_A", "上一次输出无法解析");
    }

    @Test
    void returnsClearErrorIfRepairFails() throws Exception {
        when(model.call(any(Prompt.class))).thenReturn(reply("{"));

        mvc.perform(get(ENDPOINT))
                .andExpect(status().isBadGateway())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON))
                .andExpect(jsonPath("$.detail").value("模型输出无法解析为 MaterialSummary，已尝试修复一次"));

        verify(model, times(2)).call(any(Prompt.class));
    }

    @Test
    void usesRequestedCaseAndReturnsMaterialsInDatabaseOrder() throws Exception {
        when(caseMaterialQuery.findProvidedMaterials("CASE-005")).thenReturn(Optional.of(List.of("MAT_A", "MAT_C")));
        when(model.call(any(Prompt.class))).thenReturn(reply("""
                {"caseId":"CASE-005","providedMaterials":["MAT_C","MAT_A"],"summary":"已登记两份材料。"}
                """));

        mvc.perform(get(ENDPOINT).param("caseId", "CASE-005"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.caseId").value("CASE-005"))
                .andExpect(jsonPath("$.providedMaterials[0]").value("MAT_A"))
                .andExpect(jsonPath("$.providedMaterials[1]").value("MAT_C"));

        var prompt = ArgumentCaptor.forClass(Prompt.class);
        verify(model).call(prompt.capture());
        assertThat(prompt.getValue().getUserMessage().getText()).contains("CASE-005", "[MAT_A, MAT_C]");
    }

    @Test
    void returnsNotFoundWithoutCallingModel() throws Exception {
        when(caseMaterialQuery.findProvidedMaterials("CASE-999")).thenReturn(Optional.empty());

        mvc.perform(get(ENDPOINT).param("caseId", "CASE-999"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.detail").value("未找到案件"));

        verify(model, never()).call(any(Prompt.class));
    }

    private ChatResponse reply(String text) {
        return new ChatResponse(List.of(new Generation(new AssistantMessage(text))));
    }
}
