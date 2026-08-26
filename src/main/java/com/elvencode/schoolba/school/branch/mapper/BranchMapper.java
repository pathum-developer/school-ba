package com.elvencode.schoolba.school.branch.mapper;

import java.util.List;

import com.elvencode.schoolba.school.branch.dto.BranchDto;
import com.elvencode.schoolba.school.branch.dto.SaveBranchDetailsRequest;
import com.elvencode.schoolba.school.branch.entity.Branch;
import com.elvencode.schoolba.school.entity.School;
import org.springframework.stereotype.Component;

@Component
public class BranchMapper {

    public Branch toBranch(School school, SaveBranchDetailsRequest request) {
        return new Branch(
                school,
                request.code(),
                request.name(),
                request.branchType(),
                request.address(),
                request.headOffice()
        );
    }

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
}
