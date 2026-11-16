# Spring AI 结构化输出入门（L3）

接口 `GET /ai/material-summary` 默认查询 `CASE-001`，也可以用 `caseId` 参数查询其他演示案件。MyBatis-Plus 先查 PostgreSQL 里的案件和材料，再把案件编号和材料编码交给 DeepSeek 整理。

## 1. 定义返回对象

```java
public record MaterialSummary(
        String caseId,
        List<String> providedMaterials,
        String summary) {
}
```

`record` 提供类型明确的访问方法，例如 `result.caseId()` 和 `result.providedMaterials()`。使用 `List<String>` 后，HTTP 响应里的 `providedMaterials` 是 JSON 数组。

## 2. 查 PostgreSQL，再用 `.entity()` 取得对象

`CaseMaterialQuery` 用 MyBatis-Plus 的 `BaseMapper.exists()` 检查 `claim_case` 中是否存在当前演示身份 `demo-a` 的案件，再查询 `case_material`，按材料编码排序。两次查询在同一个只读事务中执行。`case_material` 的主键由 `case_id` 和 `material_type` 组成，所以示例用一条参数化查询直接返回编码列表。

下面是核心模型调用，`caseId` 和 `providedMaterials` 来自上面的查询。

```java
MaterialSummary result = chatClient.prompt()
        .system("你是材料整理助手。保留输入的案件编号和材料编码，用一句中文总结已提供的材料。")
        .user("案件编号：%s。已提供材料编码列表：%s。".formatted(caseId, providedMaterials))
        .call()
        .entity(MaterialSummary.class);
```

L2 的 `.content()` 直接取模型回复文本。L3 的 `.entity(MaterialSummary.class)` 根据 DTO 生成 JSON Schema，将格式要求加入模型请求，再把回复解析为 Java 对象。Controller 校验此对象，Spring MVC 将通过校验的对象序列化为 HTTP JSON。 [Spring AI 2.0.2 结构化输出文档](https://docs.spring.io/spring-ai/reference/api/structured-output.html)

```text
caseId → MyBatis-Plus / PostgreSQL → ChatClient / DeepSeek → MaterialSummary → 业务校验 → HTTP JSON
```

可以在 Controller 的 `MaterialSummary result = requestSummary(caseId, providedMaterials);` 下一行打断点，观察 `result` 的 Java 类型和材料字段，再对照 curl 的响应体。

## 3. 校验字段并处理格式错误

| 模型输出 | 程序处理 |
| --- | --- |
| `caseId` 为空 | 返回 HTTP 502，给出字段为空的原因 |
| 材料中有 `MAT_X` | 返回 HTTP 502，指出材料编码无效 |
| 模型把 `CASE-001` 的材料写为 `MAT_B` | 数据库里此案件只有 `MAT_A`，返回 HTTP 502 |
| 回复无法解析为 DTO | 在原输入上增加 JSON 格式要求，再调用一次。修复仍失败时返回 HTTP 502 |

程序会对照查询结果核对案件编号和材料清单，并按数据库查询顺序返回材料。摘要文字由模型生成，示例检查它是否有内容。找不到案件或案件归属其他演示身份时返回 HTTP 404。错误原因在响应 JSON 的 `detail` 字段。

## 4. 运行和验收

使用 JDK 21，并按 Obsidian「数据库与字段设计」准备 `product`、`claim_case`、`case_material` 三张表以及合成数据。在 IDEA 的 `SpringAiApplication` 运行配置中设置 `DB_PASSWORD`，并沿用现有 DeepSeek 配置。

| 环境变量 | 用途 |
| --- | --- |
| `DB_URL` | 默认连接 `jdbc:postgresql://127.0.0.1:5432/postgres`，库名或端口不同时填写实际地址 |
| `DB_USERNAME` | 默认 `postgres` |
| `DB_PASSWORD` | 在本机运行配置中填写数据库密码 |

也可以在仓库根目录启动。在终端输入密码时，下面的命令会隐藏输入内容。

```bash
printf 'PostgreSQL password: '
read -rs DB_PASSWORD
printf '\n'
export DB_PASSWORD
mvn -pl agentLearning_spring_ai spring-boot:run
```

服务启动后发起请求。若本机修改了服务端口，替换下面的 `8080`。

```bash
curl -i http://localhost:8080/ai/material-summary
curl -i 'http://localhost:8080/ai/material-summary?caseId=CASE-005'
```

按 Obsidian 的种子数据，第二条请求返回 `["MAT_A", "MAT_C"]`。`CASE-006` 返回空数组，`CASE-007` 属于 `demo-b`，返回 HTTP 404。默认请求的响应如下，摘要措辞可变化。

```json
{
  "caseId": "CASE-001",
  "providedMaterials": ["MAT_A"],
  "summary": "案件 CASE-001 已提供材料 MAT_A。"
}
```

不用凭据也能运行自动化验收。测试用替身提供材料查询结果和模型回复，实际执行 `.entity()`、Controller 校验和 Spring MVC 序列化。

```bash
mvn -pl agentLearning_spring_ai -am test
```

[DTO](../agentLearning_spring_ai/src/main/java/com/cym/study/MaterialSummary.java) · [Controller](../agentLearning_spring_ai/src/main/java/com/cym/study/MaterialSummaryController.java) · [材料查询](../agentLearning_spring_ai/src/main/java/com/cym/study/CaseMaterialQuery.java) · [验收测试](../agentLearning_spring_ai/src/test/java/com/cym/study/MaterialSummaryControllerTest.java)
