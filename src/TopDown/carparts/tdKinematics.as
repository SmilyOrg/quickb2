/**
 * Copyright (c) 2010 Johnson Center for Simulation at Pine Technical College
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

package TopDown.carparts
{
	import TopDown.*;
	use namespace td_friend;

	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class tdKinematics
	{
		td_friend var _longSpeed:Number = 0;
		td_friend var _latSpeed:Number = 0;
		td_friend var _longAccel:Number = 0;
		td_friend var _latAccel:Number = 0;
		td_friend var _overallSpeed:Number = 0;
		
		public function get longSpeed():Number
			{  return _longSpeed;  }
			
		public function get latSpeed():Number
			{  return _latSpeed;  }
			
		public function get longAccel():Number
			{  return _longAccel;  }
			
		public function get latAccel():Number
			{  return _latAccel;  }
			
		public function get overallSpeed():Number
			{  return _overallSpeed;  }
	}
}