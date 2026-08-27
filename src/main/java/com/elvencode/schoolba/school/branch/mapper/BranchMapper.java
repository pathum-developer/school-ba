package com.elvencode.schoolba.school.branch.mapper;

import java.util.List;

import com.elvencode.schoolba.school.branch.dto.BranchDto;
import com.elvencode.schoolba.school.branch.dto.request.SaveBranchDetailsRequest;
import com.elvencode.schoolba.school.branch.entity.Branch;
import com.elvencode.schoolba.school.entity.School;
import org.springframework.beans.BeanUtils;
import org.springframework.stereotype.Component;

@Component
public class BranchMapper {

    public BranchDto toBranchDto(Branch branch) {
        return new BranchDto(
                branch.getSchool().getCode(),
                branch.getCode(),
                branch.getName(),
                branch.getBranchType(),
                branch.getAddress(),
                branch.isHeadOffice(),
                branch.isActive()
        );
    }

    public List<BranchDto> toBranchDtoList(List<Branch> branches) {
        return branches.stream()
                .map(this::toBranchDto)
                .toList();
    }

    public Branch toBranchEntity(School school, SaveBranchDetailsRequest request) {
        Branch brEntity = new Branch();
        BeanUtils.copyProperties(request,brEntity);
        brEntity.setSchool(school);
        return brEntity;
    }
}
