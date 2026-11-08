# Mermaid 渲染效果评审

这是虚构的语音助手架构，仅用于检查渲染效果，不代表任何项目已经实现的设计。
图中不指定颜色和字体，统一使用当前 Neovim 的 Mermaid 主题。

## 1. 复杂流程图：并行处理、分组与重试

重点看：分组标题是否清楚、菱形与数据库节点是否协调、长中文标签是否被截断、回路线是否容易追踪。

```mermaid
flowchart TB
    User([用户开始说话]) --> Input[语音识别与文本输入]
    Input --> Turn{是否属于当前轮次？}
    Turn -->|过期片段| Drop[丢弃并记录原因]
    Turn -->|有效输入| Context[合并上下文与用户补充]

    subgraph Foreground[前台交互 · Fast Agent]
        Context --> Intent{是否需要外部查询？}
        Intent -->|直接回答| Answer[生成简短回复]
        Intent -->|需要查询| Ack[告知正在处理]
        Ack --> Submit[提交任务与轮次编号]
        Update[接收阶段性进展] --> Speak[生成可播报的进展说明]
    end

    subgraph Background[后台执行 · Slow Agent]
        Submit --> Plan[拆解查询计划]
        Plan --> Inventory[查询库存]
        Plan --> Policy[查询业务规则]
        Inventory --> Merge[汇总工具结果]
        Policy --> Merge
        Merge --> Check{结果是否完整且一致？}
        Check -->|是| Result[生成结构化结果]
        Check -->|暂时失败| Retry{是否还有重试预算？}
        Retry -->|有，退避后重试| Plan
        Retry -->|无| Fallback[返回已有信息与失败原因]
    end

    subgraph Coordination[状态协调与交付]
        Result --> Version{结果轮次仍然有效？}
        Fallback --> Version
        Version -->|已被新请求取代| Archive[归档，不再向用户播报]
        Version -->|仍然有效| Answer
        Answer --> TTS[语音合成与播放]
        Speak --> TTS
        TTS --> Done([本次播报结束])
    end

    Merge -.->|阶段进展，不代表最终结论| Update
    Context -.->|用户改变目标时更新轮次| Version
    Plan --> Events[(任务事件记录)]
    Result --> Events
    Archive --> Events
```

## 2. 时序图：处理中补充要求与过期结果

重点看：参与者、生命线、激活条、注释、分支区域和虚线返回箭头是否清楚。横向内容较多，可用较宽的窗口查看。

```mermaid
sequenceDiagram
    autonumber
    actor U as 用户
    participant F as Fast · 前台
    participant C as 轮次协调器
    participant S as Slow · 后台
    participant T as 查询工具
    participant V as 语音播放

    U->>F: 查询明天下午可用的预约时间
    F->>C: 创建任务，轮次 v1
    C->>S: 执行查询 v1
    activate S
    F->>V: 播报：正在查询可用时间
    S->>T: 获取明天下午的空闲时段
    activate T

    Note over U,F: 后台执行期间，前台继续接收输入
    U->>F: 补充要求：只考虑三点以后的时间
    F->>C: 更新约束，轮次推进至 v2
    C-->>S: v1 已过期，请停止后续工作
    T-->>S: 返回 v1 查询结果
    deactivate T
    S->>C: 尝试提交结果 v1
    C-->>S: 拒绝交付，记录过期结果
    deactivate S

    C->>S: 执行新查询 v2
    activate S
    loop 最多两次尝试
        S->>T: 查询满足新约束的时段
        T-->>S: 返回结果或可重试错误
    end
    S->>C: 提交结果 v2
    deactivate S

    alt 当前轮次仍为 v2
        C->>F: 交付有效结果
        F->>V: 播报可选时段并询问偏好
        V-->>U: 三点半和四点还有空位
    else 用户已经发起其他请求
        C->>C: 归档结果，避免打断新对话
    end

    Note over C,V: 结果是否有效与是否允许播报，分别检查
```

## 检查记录

- [ ] 中文、英文和数字清楚，缩放后仍能阅读。
- [ ] 标签没有遮住节点，文字没有被裁掉。
- [ ] 分组、普通节点、条件节点与数据库节点有可辨识的层次。
- [ ] 复杂连线和重试回路可以追踪。
- [ ] 时序图的注释与分支区域没有刺眼的默认配色。
- [ ] 滚动、切换窗口后，图片不会残留或消失。
