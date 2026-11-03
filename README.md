# Agent Learning

```text
study_agentlearning_space/
├── pom.xml                       # 根聚合项目，无业务代码
├── version/
│   └── pom.xml                   # 公共父 POM，管理 Java / Boot / AI 版本
└── agentLearning_spring_ai/
    ├── pom.xml                   # Web MVC、DeepSeek、测试依赖及 Boot 插件
    └── src/                      # 从原项目迁入的源码和测试
```

根 POM 通过 modules 聚合两个模块；学习模块通过 parent 继承 version，
version 再继承 Spring Boot parent。聚合与继承是两个独立关系。
version 使用 packaging=pom，不生成 JAR，也不放业务依赖。

版本：Java 21、Spring Boot 4.0.9、Spring AI 2.0.2。
修改 Boot 版本请改 version/pom.xml 的 parent/version；修改 AI 或 Java 版本请改其 properties。
业务模块只声明需要的依赖，不单独写版本号。

## IDEA

重新加载根 pom.xml，两个模块会自动导入。不要继续使用旧 spring-ai-demo 模块路径。
启动类：`agentLearning_spring_ai/src/main/java/com/cym/study/SpringAiApplication.java`。
最小配置：`agentLearning_spring_ai/src/main/resources/application.yml`。
在 IDEA 启动配置的 Environment variables 中设置 `DEEPSEEK_API_KEY`，运行启动类即可。
模型默认为 `deepseek-v4-flash`，可通过 `DEEPSEEK_MODEL` 覆盖；服务默认监听 8080。
当前只添加启动入口与配置，尚未添加问答接口。

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
