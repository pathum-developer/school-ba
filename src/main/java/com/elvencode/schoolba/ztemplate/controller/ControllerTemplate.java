package com.elvencode.schoolba.ztemplate.controller;

import com.elvencode.schoolba.ztemplate.dto.DtoTemplate;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/controller-template")
public class ControllerTemplate {

    //     ToDo
    @PostMapping
    public String readRequestBodyData(@RequestBody DtoTemplate dtoTemplate){
        return "created data class with the data: "+dtoTemplate.toString();
    }
}
