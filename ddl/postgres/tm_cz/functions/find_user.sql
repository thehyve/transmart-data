--
-- Name: find_user(character varying); Type: FUNCTION; Schema: tm_cz; Owner: -
--
CREATE FUNCTION find_user(user_type character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
/*************************************************************************
* Copyright 2008-2012 Janssen Research & Development, LLC.
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
******************************************************************/
declare
	userName	character varying;
BEGIN

	if user_type = 'S' then
		select session_user into userName;
	else
		select current_user into userName;
	end if;

  
	return userName;
  

END;

$$;

