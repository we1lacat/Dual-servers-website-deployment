package site.we1l.service;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import org.springframework.stereotype.Service;
import site.we1l.entity.Skill;
import site.we1l.mapper.SkillMapper;

import java.util.List;

/**
 * 技能服务（进度条 BAR 与雷达图 RADAR 共用一张表）。
 */
@Service
public class SkillService extends BaseService<SkillMapper, Skill> {

    public List<Skill> listByType(String type) {
        return lambdaQuery()
                .eq(Skill::getSkillType, type)
                .eq(Skill::getStatus, 1)
                .orderByAsc(Skill::getSortOrder)
                .orderByAsc(Skill::getId)
                .list();
    }

    /** 后台：按类型分页查询（不带状态过滤） */
    public Page<Skill> pageByType(Page<Skill> page, String type) {
        return page(page, Wrappers.<Skill>lambdaQuery()
                .eq(type != null && !type.isBlank(), Skill::getSkillType, type)
                .orderByAsc(Skill::getSkillType)
                .orderByAsc(Skill::getSortOrder)
                .orderByAsc(Skill::getId));
    }
}
