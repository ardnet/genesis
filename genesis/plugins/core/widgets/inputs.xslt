<xsl:template match="formline">
    <div class="{x:iif(@checkbox, 'checkbox', 'form-group')}{x:iif(@feedback != '', ' has-feedback', '')}">
        <hlabel class="control-label" for="{@iid}" text="{@text}" />
        <xsl:apply-templates />
        <xsl:if test="@feedback">
            <span class="{@feedback} form-control-feedback"></span>
        </xsl:if>
        <xsl:if test="@help">
            <span class="help-block">
                <xsl:value-of select="@help" />
            </span>
        </xsl:if>
    </div>
</xsl:template>

<xsl:template match="textinput">
    <input name="{@name}" value="{@value}" id="{@id}" class="form-control {@design}" type="{x:iif(@password, 'password', 'text')}">
        <xsl:if test="@disabled != ''">
            <xsl:attribute name="disabled">true</xsl:attribute>
        </xsl:if>
        <xsl:if test="@verify != ''">
            <xsl:choose>
                <xsl:when test="@verify = 'password'">
                    <xsl:attribute name="onkeypress">Genesis.verify('passwd', '<xsl:value-of select="@verify-with" />', '<xsl:value-of select="@verify-with" />b', event)</xsl:attribute>
                </xsl:when>
                <xsl:when test="@verify = 'username'">
                    <xsl:attribute name="onblur">Genesis.verify('user', '<xsl:value-of select="@id" />', '', event)</xsl:attribute>
                </xsl:when>
            </xsl:choose>
        </xsl:if>
    </input>
</xsl:template>

<xsl:template match="attachtextinput">
    <div class="input-prepend">
        <hlabel class="add-on {@attachmentDesign}">
            <xsl:apply-templates />
        </hlabel>
        <input name="{@name}" value="{@value}" id="{@id}" class="{@design}" onkeypress="return noenter()" type="{x:iif(@password, 'password', 'text')}" />
    </div>
</xsl:template>

<xsl:template match="checkbox">
    <input type="checkbox" name="{@name}" id="{@id}" onkeypress="return noenter()">
        <xsl:if test="@checked = 'True'">
            <xsl:attribute name="checked"/>
        </xsl:if>
    </input>
    <xsl:value-of select="@text" />
</xsl:template>


<xsl:template match="selectinput">
    <select name="{@name}" id="{@id}" class="form-control{x:iif(@design, ' '+@design, '')}">
        <xsl:if test="@disabled != ''">
            <xsl:attribute name="disabled" />
        </xsl:if>
        <xsl:apply-templates />
    </select>
</xsl:template>

<xsl:template match="selectoption">
    <option value="{@value}" onkeypress="return noenter()">
        <xsl:if test="@selected = 'True'">
            <xsl:attribute name="selected"/>
        </xsl:if>
        <xsl:value-of select="@text" />
    </option>
</xsl:template>

<xsl:template match="radio">
    <div class="ui-el-radio">
        <input type="radio" value="{@value}" name="{@name}" id="{@id}" onkeypress="return noenter()">
            <xsl:if test="@checked = 'True'">
                <xsl:attribute name="checked"/>
            </xsl:if>
        </input>
        <xsl:value-of select="@text" />
    </div>
</xsl:template>

<xsl:template match="textinputarea">
    <textarea class="ui-el-textarea" name="{@name}" style="width: {x:css(@width, '200')}; height: {x:css(@height, '200')};" 
        id="{@id}">
        <xsl:if test="@disabled = 'True'">
            <xsl:attribute name="disabled"/>
        </xsl:if>
    </textarea>
    <script>
        <xsl:choose>
            <xsl:when test="@nodecode = 'True'">
                ui_fill_custom_html('<xsl:value-of select="@id"/>', '<xsl:value-of select="@value"/>');
            </xsl:when>
            <xsl:otherwise>
                ui_fill_custom_html('<xsl:value-of select="@id"/>', '<xsl:value-of select="x:b64(@value)"/>');
            </xsl:otherwise>
        </xsl:choose>
    </script>
</xsl:template>

<xsl:template match="selecttextinput">
    <input name="{@name}" value="{@value}" id="{@id}" class="{@design}" onkeypress="return noenter()" type="text"/>
    <select onchange="$('#{@id}').val(this.value)" id='{@id}-hints' class="{@design}">
        <option selected="">...</option>
        <xsl:apply-templates/>
    </select>
</xsl:template>

<xsl:template match="uploader">
    <form action="{@url}" method="POST" enctype="multipart/form-data">
        <input type="file" name="file"/>
        <input type="submit" class="ui-el-button" value="{x:attr(@text, 'Upload')}"/>
    </form>
</xsl:template>

<xsl:template match="fileinput">
    <xsl:choose>
        <xsl:when test="@multiple != ''">
            <input type="file" name="{@id}" multiple="True" />
        </xsl:when>
        <xsl:otherwise>
            <input type="file" name="{@id}" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="appselect">
    <div class="ui-firstrun-appselect" id="{@id}" onclick="Genesis.appListClick('{@id}')">
        <input type="checkbox" name="install-{@id}" />
        <div class="pull-left" style="height:100%;">
            <h2 class="{@iconfont}"></h2>
        </div>
        <h4><xsl:value-of select="@name"/></h4>
        <small><xsl:value-of select="@desc"/></small>
        <h6>Version <xsl:value-of select="@version"/></h6>
    </div>
</xsl:template>

<xsl:template match="authorization">
    <div class="shadebox" id="authbox">
        <h3><i class="gen-key pull-right"></i>Authorization required</h3>
        <xsl:if test="@status != ''">
            <systemmessage cls="danger" iconfont="gen-close" text="{@status}" />
        </xsl:if>
        <p id="auth-text"><strong><xsl:value-of select="@app"/></strong> needs your authorization for the following operation:</p>
        <p id="auth-reason"><xsl:value-of select="@reason"/></p>
        <simpleform id="dlgAuthorize" type="dialog">
            <input type="hidden" id="auth-metadata" name="auth-metadata" value="{@meta}" />
            <formline text="{@label}">
                <textinput name="auth-string" id="auth-string" password="true" />
            </formline>
            <div class="shadebox-footer">
                <btn text="Authorize" action="OK" design="outline-inverse-warn" size="reg" form="dlgAuthorize" onclick="form" />
                <btn text="Cancel" action="Cancel" href="#" design="outline-inverse-gray" size="reg" form="dlgAuthorize" onclick="form">Cancel</btn>
            </div>
        </simpleform>
    </div>
    <script>
        Genesis.showAuthorization()
        Genesis.submitOnEnter('dlgAuthorize');
    </script>
</xsl:template>
