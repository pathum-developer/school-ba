package com.elvencode.schoolba.school.branch.aspects;

import lombok.extern.slf4j.Slf4j;
import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.annotation.AfterReturning;
import org.aspectj.lang.annotation.AfterThrowing;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Before;
import org.springframework.stereotype.Component;

import java.util.Arrays;

@Aspect
@Component
@Slf4j
public class BranchAuditAspect {

//    @Before("""
//            execution(* com.elvencode.schoolba.school.branch.service.impl.BranchServiceImpl.saveBranchDetails(..))
//                    || execution(* com.elvencode.schoolba.school.branch.service.impl.BranchServiceImpl.patchBranchDetails(..))
//                    || execution(* com.elvencode.schoolba.school.branch.service.impl.BranchServiceImpl.deleteBranchByCode(..))
//            """)
    @Before("@annotation(com.elvencode.schoolba.common.aspects.LogMethodSignature)")
    public void auditBranchChange(JoinPoint joinPoint) {
        log.info(
                "Branch change requested: method={}, args={}",
                joinPoint.getSignature().toShortString(),
                Arrays.toString(joinPoint.getArgs())
        );
    }

    @AfterReturning("""
            execution(* com.elvencode.schoolba.school.branch.service.impl.BranchServiceImpl.deleteBranchByCode(..))
            """)
    public void auditSuccessfulBranchDelete(JoinPoint joinPoint) {
        log.info(
                "Branch delete completed: method={}, args={}",
                joinPoint.getSignature().toShortString(),
                Arrays.toString(joinPoint.getArgs())
        );
    }

    @AfterThrowing(
            pointcut = """
                    execution(* com.elvencode.schoolba.school.branch.service.impl.BranchServiceImpl.saveBranchDetails(..))
                            || execution(* com.elvencode.schoolba.school.branch.service.impl.BranchServiceImpl.patchBranchDetails(..))
                            || execution(* com.elvencode.schoolba.school.branch.service.impl.BranchServiceImpl.deleteBranchByCode(..))
                    """,
            throwing = "exception"
    )
    public void auditFailedBranchChange(JoinPoint joinPoint, Exception exception) {
        log.error(
                "Branch change failed: method={}, args={}, exceptionType={}, message={}",
                joinPoint.getSignature().toShortString(),
                Arrays.toString(joinPoint.getArgs()),
                exception.getClass().getSimpleName(),
                exception.getMessage()
        );
    }
}
