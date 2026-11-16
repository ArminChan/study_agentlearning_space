package com.cym.study;

import java.util.List;
import java.util.Optional;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.cym.study.persistence.CaseMaterialMapper;
import com.cym.study.persistence.ClaimCase;
import com.cym.study.persistence.ClaimCaseMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Transactional;

@Service
public class CaseMaterialQuery {
    // 学习案例在服务端固定使用 demo-a，调用方只传案件编号。
    private static final String DEMO_OWNER_ID = "demo-a";

    private final ClaimCaseMapper cases;
    private final CaseMaterialMapper materials;

    public CaseMaterialQuery(ClaimCaseMapper cases, CaseMaterialMapper materials) {
        this.cases = cases;
        this.materials = materials;
    }

    // 两次查询共用一个 PostgreSQL 快照，保证案件归属和材料清单来自同一个数据视图。
    @Transactional(readOnly = true, isolation = Isolation.REPEATABLE_READ)
    public Optional<List<String>> findProvidedMaterials(String caseId) {
        // MyBatis-Plus 根据实体取值方法映射列名，按案件编号和归属判断案件是否可查。
        boolean exists = cases.exists(Wrappers.<ClaimCase>lambdaQuery()
                .eq(ClaimCase::getCaseId, caseId)
                .eq(ClaimCase::getOwnerId, DEMO_OWNER_ID));
        if (!exists) {
            return Optional.empty();
        }

        // 查得到案件但没有材料时，返回包含空列表的 Optional，与查不到案件区分。
        return Optional.of(List.copyOf(materials.findMaterialTypes(caseId)));
    }
}
