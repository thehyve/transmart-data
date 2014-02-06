--
-- Name: is_number(character varying); Type: FUNCTION; Schema: tm_cz; Owner: -
--
CREATE FUNCTION is_number(character varying) RETURNS numeric
    LANGUAGE plpgsql IMMUTABLE SECURITY DEFINER
    AS $_$
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
DECLARE
	i_number		ALIAS FOR $1;
	
	v_number		numeric;
	
BEGIN
	v_number := i_number;
		
    return 0;
  exception
       when others then
           return 1;

   

END;


$_$;

