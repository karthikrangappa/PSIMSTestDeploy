function ShowLoggedInUser(username) {
    $("#LogoutMenu").hide();
    $('#btnGenerateDoc').addClass('SubmitButton');
    $('.navbar-text.form-title.hidden-xs').text('Permits Online');
    $('#lnkHome').hide();
    $("#plhCustomUI").addClass("backtodashboarddiv");
    $(".navbar-right").html('<div><div class="triangle-topleft"></div><div class="toprightdiv"><div class="dropdown"><a class="btn btn-primary dropdown-toggle" data-toggle="dropdown" href="#..">' + username + '<span class="caret"></span></a><ul class="dropdown-menu"><li><a href="http://permitsonlinedev.azurewebsites.net/Produce/Form/Public/My%20Profile/">Account Details</a></li><li><a id="lnkSignOut" class="signout-link" href="/Produce/Account/LogOff">Log Out</a></li></ul></div></div></div>');
    var hasCont = $(".amendment-status").contents().length ? $(".amendment-status").show() : $(".amendment-status").hide();
    $('#ProjectAnswerFiles').hide();
}

function ShowNavControlsInFooter() {
    var navDivhtml = $('.pageNav').html();
    var nextPagehtml = $(".fr").html();
    if (navDivhtml && nextPagehtml) {
        $(".fr").html('<table><tbody><tr><td class="pageNav">' + navDivhtml + '</td></tr></tbody></table>');
    }
}

function ShowHeaderWithProjectName(projectName,projectDesc,amendmentStatus,amendmentNumber) {

    if (projectName === 'Sign Up') {
        ApplyStyleForSignUp();
        $(".navbar-right").html('<div><div class="triangle-topleft"></div><div class="toprightdiv"><a href = "http://permitsonlinedev.azurewebsites.net/Produce/Account/Login">Log In</a></div></div>');
        $('.Group').addClass('formwrapper');
    }
    else {
        var headerHtml = $('.navbar.navbar-inverse.navbar-fixed-top.ix-nav').html();
        if (!$('#formHeader').length) {
            $('.navbar.navbar-inverse.navbar-fixed-top.ix-nav').html(headerHtml+'<div id="formHeader" class="headerdiv"><div class="header-leftaside"><h1>'+projectName+'</h1><div class="appform-subtitle">'+projectDesc+'</div></div><div class="amenment-details"><span class="amendment-num">'+amendmentNumber+'</span><span class="amendment-status">'+amendmentStatus+'</span></div></div>');
        }
    }
}

function ApplyStyleForSignUp() {
    $('.Group').addClass('leftBorder');
    $('.lsh').addClass('signuplabel');
    $('#PageBody').addClass('signuppagediv');
    $('.ls.alert.alert-info').addClass('signupdiv');
}

function CustomContainer(projectName){
    if (projectName === 'Successful Sign Up') {
        $('#btnGenerateDoc').hide();
        $('.Group').addClass('leftBorder');
        $('#page-title').hide();
        
        $('.l-row').addClass('successfulsignupdiv');
        //$('.question-body').addClass('successfulsignupdiv');
        var varFirstQuestion=$('.question-body')[0];
        varFirstQuestion.style.paddingTop="15%";
    }
    else if (projectName === 'Application Category'){
        $('.Group').addClass('LandingGroupCenterContainer');
    }
    else if (projectName === 'MPP Application Type'){
        $('.Group').addClass('GroupCenterContainer');
    }
    else if (projectName === 'Pre-Application Types'){
        $('.Group').addClass('GroupCenterContainer');
    }
    else if (projectName === 'Planning (Ministerial Application)'){
        $('.Group').addClass('GroupCenterContainer');
    }
    else if (projectName === 'Development Plan'){
        $('.Group').addClass('GroupCenterContainer');
    }
    else if (projectName === 'Consent under Incorporated Document'){
        $('.Group').addClass('GroupCenterContainer');
    }
    else if (projectName === 'Planning Permit'){
        $('.Group').addClass('GroupCenterContainer');
    }
    else if (projectName === 'VicSmart Planning Permit'){
        $('.Group').addClass('GroupCenterContainer');
    }
    else if (projectName === 'Application Type'||projectName==="Application Form Type"||projectName==="Submissions and Hearings"||projectName==="Heritage Council Application Type"||projectName==="HPA Form Type"){
        $('.Group').addClass('GroupCenterContainer');
    }
    else if (projectName === 'HC Form A')
    {
        $('body').addClass('HCForms');
    }
    else if (projectName === 'HC Form B')
    {
        $('body').addClass('HCForms');
    }
    else if (projectName === 'HC Form E')
    {
        $('body').addClass('HCForms');
    }
    else if (projectName === 'Nomination Review')
    {
        $('body').addClass('HCForms');
    }
    else if (projectName === 'Heritage Council – Submission in Reply')
    {
        $('body').addClass('HCForms');
    }

}
