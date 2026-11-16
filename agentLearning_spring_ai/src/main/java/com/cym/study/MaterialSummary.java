package com.cym.study;

import java.util.List;

// L3 的结构化响应 DTO，声明了模型回复与 HTTP JSON 共用的三个字段。
public record MaterialSummary(String caseId, List<String> providedMaterials, String summary) {
}
