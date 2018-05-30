--
-- Copyright 2017 Konrad Haeublein
--
-- konrad.haeublein@fau.de
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package pkg_functions is

function f_log2(a: integer) return integer;
function f_ramlog2(a: integer) return integer;
function even(a: integer) return boolean;
function div(a: integer;b: integer) return integer;
function udiv(a: integer;b: integer) return integer;
function unevensearch(a: integer;b: integer) return integer;

end pkg_functions;

package body pkg_functions is

function f_log2(a: integer) return integer is
begin
	for i in 1 to 30 loop -- up 32 bit integer
		if(2**i > a) then return(i); end if;
	end loop;
	return(30);
end;

function f_ramlog2(a: integer) return integer is
begin
	for i in 1 to 30 loop -- up 32 bit integer
		if(2**i > a) then
			return(i-1);
			end if;
	end loop;
	return(30);
end;

function even(a: integer) return boolean is
begin
	if((a mod 2) /= 0) then
		return(false);
	else 
		return(true);
	end if;
end;

function div(a: integer;b: integer) return integer is
variable c: integer;
begin
	c := a/2**(b+1);
	return(c);
end;

function udiv(a: integer;b: integer) return integer is
variable c: integer;
begin
	if (b = 0) then
		c := a;
	else
		c := a/2**(b);
	end if;
	return(c);
end;

function unevensearch(a: integer;b: integer) return integer is
variable c,d: integer;
begin
	for i in 0 to b loop
		if (i=0) then
			c:= a;
		else
			c := a/2**(i);
		end if;
		if(c mod 2/= 0)  then
			d:=i;
			exit;
		end if;
	end loop;
	return(d);
end;

end pkg_functions;