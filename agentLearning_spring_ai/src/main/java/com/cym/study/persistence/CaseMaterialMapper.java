package com.cym.study.persistence;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

@Mapper
public interface CaseMaterialMapper {
    // case_material 使用联合主键。这条只读查询直接返回所需的材料编码。
    // #{caseId} 绑定 SQL 参数，ORDER BY 保证材料在每次请求中按同一顺序返回。
    @Select("""
            SELECT material_type
            FROM case_material
            WHERE case_id = #{caseId}
            ORDER BY material_type
            """)
    List<String> findMaterialTypes(@Param("caseId") String caseId);
}
