package com.cym.study.persistence;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;

// 案件表映射，只声明本次按编号和归属查询所需的字段。
@TableName("claim_case")
public class ClaimCase {
    // case_id 是业务编号，使用已有的 CASE-xxx 值。
    @TableId(value = "case_id", type = IdType.INPUT)
    private String caseId;
    private String ownerId;

    public String getCaseId() {
        return caseId;
    }

    public void setCaseId(String caseId) {
        this.caseId = caseId;
    }

    public String getOwnerId() {
        return ownerId;
    }

    public void setOwnerId(String ownerId) {
        this.ownerId = ownerId;
    }
}
