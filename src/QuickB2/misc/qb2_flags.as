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

package QuickB2.misc 
{
	import QuickB2.*;
	use namespace qb2_friend;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2_flags
	{
		// for all objects
		public static const JOINS_IN_DEEP_CLONING:uint       = 0x00000001;
		public static const JOINS_IN_DEBUG_DRAWING:uint      = 0x00000002;
		public static const JOINS_IN_UPDATE_CHAIN:uint       = 0x00000004;
		
		// for tangibles
		public static const IS_KINEMATIC:uint                = 0x00000008;
		public static const IS_BULLET:uint                   = 0x00000010;
		public static const IS_GHOST:uint                    = 0x00000020;
		public static const ALLOW_SLEEPING:uint              = 0x00000040;
		public static const SLEEPING_WHEN_ADDED:uint         = 0x00000080;
		public static const IS_DEBUG_DRAGGABLE:uint          = 0x00000100;
		public static const HAS_FIXED_ROTATION:uint          = 0x00000200;
		
		// for joints
		public static const COLLIDE_CONNECTED:uint           = 0x00000400;
		public static const OPTIMIZED_SPRING:uint            = 0x00000800;
		public static const DAMPEN_SPRING_JITTER:uint        = 0x00001000;
		public static const SPRING_CAN_FLIP:uint             = 0x00002000;
		public static const IS_ROPE:uint                     = 0x00004000;
		public static const AUTO_SET_LENGTH:uint             = 0x00008000;
		public static const AUTO_SET_DIRECTION:uint          = 0x00010000;
		public static const FREE_ROTATION:uint               = 0x00020000;
		
		// for polygons
		public static const ALLOW_COMPLEX_POLYGONS:uint      = 0x00040000;
		
		// for internal use only
		qb2_friend static const IS_DEEP_CLONING:uint         = 0x08000000;
		qb2_friend static const REPORTS_CONTACT_STARTED:uint = 0x10000000;
		qb2_friend static const REPORTS_CONTACT_ENDED:uint   = 0x20000000;
		qb2_friend static const REPORTS_PRE_SOLVE:uint       = 0x40000000;
		qb2_friend static const REPORTS_POST_SOLVE:uint      = 0x80000000;
		qb2_friend static const CONTACT_REPORTING_FLAGS:uint = REPORTS_CONTACT_STARTED | REPORTS_CONTACT_ENDED |
		                                                       REPORTS_PRE_SOLVE       | REPORTS_POST_SOLVE    ;
		qb2_friend static const RESERVED_FLAGS:uint          = IS_DEEP_CLONING | CONTACT_REPORTING_FLAGS;
	}
}