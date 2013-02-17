/**
 * Copyright (C) 2013 ANDLABS. All rights reserved.
 * Author: Shawn Davies <sodxeh@gmail.com>
 * This login script contains all functions related to the login protocol of lounge.
 */

function Login() {
    if (empty($_POST['username'])) {
	$this->HandleError("Username field blank!");
	return false;
    }
}
