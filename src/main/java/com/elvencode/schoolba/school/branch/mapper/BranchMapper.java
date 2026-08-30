package com.elvencode.schoolba.school.branch.mapper;

import java.util.Comparator;
import java.util.List;

import com.elvencode.schoolba.school.branch.dto.BranchDto;
import com.elvencode.schoolba.school.branch.dto.ContactNoDto;
import com.elvencode.schoolba.school.branch.dto.request.PatchBranchDetailsRequest;
import com.elvencode.schoolba.school.branch.dto.request.SaveBranchDetailsRequest;
import com.elvencode.schoolba.school.branch.dto.request.SaveContactNoRequest;
import com.elvencode.schoolba.school.branch.entity.Branch;
import com.elvencode.schoolba.school.branch.entity.BranchContactNo;
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
                branch.isActive(),
                toContactNoDtoList(branch.getContactNoList())
        );
    }

    public List<BranchDto> toBranchDtoList(List<Branch> branchList) {
        return branchList.stream()
                .map(this::toBranchDto)
                .toList();
    }

    public List<ContactNoDto> toContactNoDtoList(List<BranchContactNo> contactNoList) {
        return contactNoList.stream()
                .sorted(Comparator.comparingInt(BranchContactNo::getDisplayOrder))
                .map(this::toContactNoDto)
                .toList();
    }

    public ContactNoDto toContactNoDto(BranchContactNo contactNo) {
        return new ContactNoDto(
                contactNo.getContactType(),
                contactNo.getPhoneNumber(),
                contactNo.getPhoneNumberE164(),
                contactNo.isPrimary(),
                contactNo.getDisplayOrder()
        );
    }

    public Branch toBranchEntity(School school, SaveBranchDetailsRequest request) {
        Branch brEntity = new Branch();
        BeanUtils.copyProperties(request, brEntity, "contactNoList");
        brEntity.setSchool(school);
        brEntity.getContactNoList().addAll(toBranchContactNoList(brEntity, request.contactNoList()));
        return brEntity;
    }

    public void patchBranchEntity(Branch branch, PatchBranchDetailsRequest request) {
        if (request.name() != null) {
            branch.setName(request.name());
        }
        if (request.branchType() != null) {
            branch.setBranchType(request.branchType());
        }
        if (request.address() != null) {
            branch.setAddress(request.address());
        }
        if (request.headOffice() != null) {
            branch.setHeadOffice(request.headOffice());
        }
        if (request.active() != null) {
            branch.setActive(request.active());
        }
        if (request.contactNoList() != null) {
            replaceBranchContactNoList(branch, request.contactNoList());
        }
    }

    private void replaceBranchContactNoList(Branch branch, List<SaveContactNoRequest> contactNoRequestList) {
        branch.getContactNoList().clear();
        branch.getContactNoList().addAll(toBranchContactNoList(branch, contactNoRequestList));
    }

    private List<BranchContactNo> toBranchContactNoList(Branch branch, List<SaveContactNoRequest> contactNoRequestList) {
        if (contactNoRequestList == null) {
            return List.of();
        }
        return contactNoRequestList.stream()
                .map(contactNoRequest -> toBranchContactNo(branch, contactNoRequest))
                .toList();
    }

    private BranchContactNo toBranchContactNo(Branch branch, SaveContactNoRequest request) {
        BranchContactNo contactNo = new BranchContactNo();
        contactNo.setBranch(branch);
        if (request.contactType() != null) {
            contactNo.setContactType(request.contactType());
        }
        contactNo.setPhoneNumber(request.phoneNumber());
        contactNo.setPhoneNumberE164(request.phoneNumberE164());
        contactNo.setPrimary(request.primary());
        contactNo.setDisplayOrder(request.displayOrder());
        return contactNo;
    }
}
