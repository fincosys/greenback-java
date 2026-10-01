package com.greenback.kit.util;

import com.greenback.kit.model.Form;
import com.greenback.kit.model.FormField;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.Map;
import static org.hamcrest.CoreMatchers.is;
import static org.junit.Assert.assertThat;
import org.junit.Test;

public class FormsTest {

    @Test
    public void computeAndValidateParameters() {
        final FormField code = new FormField();
        code.setType("text");
        code.setName("code");
        code.setLabel("Code");
        code.setRequired(true);
        code.setValue("123");

        final Form form = new Form();
        form.setFields(Arrays.asList(code));

        final Map<String, String> params = Forms.computeParameters(form);
        assertThat(params.get("code"), is("123"));
        assertThat(Forms.isCompleted(form, params), is(true));

        final Map<String, String> empty = new LinkedHashMap<>();
        empty.put("code", "");
        assertThat(Forms.isCompleted(form, empty), is(false));
        assertThat(Forms.unmappedMessages(form, empty).isEmpty(), is(false));
    }

}
