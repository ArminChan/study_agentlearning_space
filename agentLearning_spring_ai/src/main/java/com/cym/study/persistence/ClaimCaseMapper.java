package com.cym.study.persistence;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;

// MyBatis 注册 Mapper 实例，MyBatis-Plus 的 BaseMapper 提供 exists 等通用查询方法。
@Mapper
public interface ClaimCaseMapper extends BaseMapper<ClaimCase> {
}
