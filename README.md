# Agent Learning

```text
study_agentlearning_space/
├── pom.xml                       # 根聚合项目，无业务代码
├── version/
│   └── pom.xml                   # 公共父 POM，管理 Java / Boot / AI 版本
└── agentLearning_spring_ai/
    ├── pom.xml                   # Web MVC、DeepSeek、MyBatis-Plus、PostgreSQL 与测试
    └── src/                      # 从原项目迁入的源码和测试
```

根 POM 通过 modules 聚合两个模块；学习模块通过 parent 继承 version，
version 再继承 Spring Boot parent。聚合与继承是两个独立关系。
version 使用 packaging=pom，不生成 JAR，也不放业务依赖。

版本包括 Java 21、Spring Boot 4.0.9、Spring AI 2.0.2 和 MyBatis-Plus 3.5.17。
修改 Boot 版本请改 version/pom.xml 的 parent/version；修改 Spring AI、Java 或 MyBatis-Plus 版本请改其 properties。
业务模块只声明需要的依赖，不单独写版本号。

## IDEA

重新加载根 pom.xml，两个模块会自动导入。不要继续使用旧 spring-ai-demo 模块路径。
启动类：`agentLearning_spring_ai/src/main/java/com/cym/study/SpringAiApplication.java`。
最小配置：`agentLearning_spring_ai/src/main/resources/application.yml`。
在 IDEA 启动配置的 Environment variables 中设置 `DEEPSEEK_API_KEY`，运行启动类即可。
模型默认为 `deepseek-v4-flash`，可通过 `DEEPSEEK_MODEL` 覆盖；服务默认监听 8080。
材料摘要接口需要在运行配置中设置 `DB_PASSWORD`。默认连接本机 `127.0.0.1:5432/postgres`，用户名为 `postgres`。可用 `DB_URL` 与 `DB_USERNAME` 覆盖。

已有文本问答接口 `GET /ai/chat`。结构化输出练习见 [Spring AI 结构化输出入门（L3）](docs/Spring%20AI%20结构化输出入门（L3）.md)。

## 数据库 SQL

在现有 pgvector 数据库的查询窗口打开 [sql/](sql/) 中的文件，按阶段整份执行。已经初始化 G0 的学习库可以从后续阶段开始。

- G0 新库依次执行 [g0-schema.sql](sql/g0-schema.sql) 和 [g0-seed.sql](sql/g0-seed.sql)。
- G3 依次执行 [g3-schema.sql](sql/g3-schema.sql)、[g3-seed.sql](sql/g3-seed.sql)、[g3-vector-schema.sql](sql/g3-vector-schema.sql)。向量维度默认 1024，需要时在脚本内改成模型实际维度。执行后可以用 [g3-check.sql](sql/g3-check.sql) 核对。
- G4 执行 [g4-schema.sql](sql/g4-schema.sql)，按需执行 [g4-seed.sql](sql/g4-seed.sql) 导入确认样例，用 [g4-check.sql](sql/g4-check.sql) 核对运行、草稿和待办。

## 构建

在根目录执行：

```shell
mvn verify
```

只构建学习模块及其父项目：

```shell
mvn -pl agentLearning_spring_ai -am verify
```

后续新增模块：根 POM 的 modules 中加入目录，并让新模块继承 version/pom.xml。
