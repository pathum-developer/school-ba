package com.elvencode.schoolba.ztemplate.controller;

import com.elvencode.schoolba.ztemplate.dto.DtoTemplate;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/controller-template")
public class ControllerTemplate {

    //     ToDo
    @GetMapping(value = {
            "/pa-var-1/{var1}",
            "/pa-var-1/{var1}/pa-var-2/{var2}"
    }, version = "1.0+")
    public ResponseEntity<String> readDataWithMultiplePathVariables(
            @PathVariable (name="var1") String var1Value,
            @PathVariable(required = false) String var2
    ) {
        String response;
        if (var2 == null) {
            response ="readDataWithMultiplePathVariables is not implemented yet."+var1Value;
        }else{
            response ="readDataWithMultiplePathVariables is not implemented yet."+var1Value+" "+var2;
        }
       return ResponseEntity.ok().body(response);
    }

    //     ToDo
    @GetMapping(value = "/pa-var1/{var1}/pa-var2/{var2}", version = "1.0+")
    public String readPathVariablesUsingMap(@PathVariable Map<String,String> filterMap) {
        throw new RuntimeException("readPathVariablesUsingMap is not implemented yet."+filterMap.get("var1") +"->"+ filterMap.get("var2"));
    }

    //     ToDo
    @GetMapping(value = "/search", version = "1.0+")
    public String readDataWithRequestParams(@RequestParam (required = false, defaultValue = "001", name = "var1") String variableValue) {
        throw new RuntimeException("readDataWithRequestParams is not implemented yet."+variableValue);
    }

    //     ToDo
    @GetMapping(value = "/headers", version = "1.0+")
    public String readDataRequestHeaders(@RequestHeader("User-Agent") String userAgent,@RequestHeader(name = "User-location", required = false) String userLocation) {
        throw new RuntimeException("readDataRequestHeaders is not implemented yet."+userAgent +" -> "+userLocation);
    }

    //     ToDo
    @GetMapping(value = "/user-headers", version = "1.0+")
    public String readRequestHeadersByHttpHeaders(@RequestHeader HttpHeaders requestHeaders) {
        throw new RuntimeException("readRequestHeaders is not implemented yet."+requestHeaders.get("User-Agent") );
    }

    //     ToDo
    @PostMapping
    public ResponseEntity<String> readRequestBodyData(@RequestBody DtoTemplate dtoTemplate){
        return ResponseEntity.status(HttpStatus.CREATED).body("created data class with the data: "+dtoTemplate.toString()) ;
    }
}
