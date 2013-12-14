/*
 *
 * CODENVY CONFIDENTIAL
 * ________________
 *
 * [2012] - [2013] Codenvy, S.A.
 * All Rights Reserved.
 * NOTICE: All information contained herein is, and remains
 * the property of Codenvy S.A. and its suppliers,
 * if any. The intellectual and technical concepts contained
 * herein are proprietary to Codenvy S.A.
 * and its suppliers and may be covered by U.S. and Foreign Patents,
 * patents in process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material
 * is strictly forbidden unless prior written permission is obtained
 * from Codenvy S.A..
 */


package com.codenvy.analytics.services.view;

import com.codenvy.analytics.datamodel.StringValueData;
import com.codenvy.analytics.datamodel.ValueData;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;

/** @author <a href="mailto:abazko@codenvy.com">Anatoliy Bazko</a> */
class EmptyRow extends AbstractRow {

    public EmptyRow(Map<String, String> parameters) {
        super(parameters);
    }

    @Override
    public List<List<ValueData>> getData(Map<String, String> initialContext, int columns) throws IOException {
        List<ValueData> result = new ArrayList<>(columns);

        for (int i = 0; i < getOverriddenColumnsCount(columns); i++) {
            result.add(StringValueData.DEFAULT);
        }

        return Arrays.asList(result);
    }
}