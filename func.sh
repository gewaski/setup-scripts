# !/bin/bash
# Copyright (c) 2014
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# zhangwei13 <alucard.hust@gmail.com>
#


function local_exec()
{
    expect -c "
    spawn $1
    expect {
        \"$2\" {send \"$3\r\"; exp_continue;}
          }
    expect eof"
}


function remote_exec()
{
    expect -c "
    spawn ssh work@$1 \"$3\"
    expect {
        \"yes/no\" {send \"yes\r\"; exp_continue;}
        \"*assword\" {set timeout 300; send \"$2\r\";}
          }
    expect eof"
}

function remote_scp()
{
    expect -c "
        spawn scp -r $3 work@$1:$4
        expect {
            \"yes/no\" {send \"yes\r\"; exp_continue;}
            \"*assword\" {set timeout 300; send \"$2\r\";}
        }
    expect eof"
}

function remote_scp_back()
{
	expect -c "
	    spawn scp -r work@$1:$3 $4
	    expect {
	        \"yes/no\" {send \"yes\r\"; exp_continue;}
	        \"*assword\" {set timeout 300; send \"$2\r\";}
	    }
	expect eof"
}
