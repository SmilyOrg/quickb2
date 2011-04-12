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

package TopDown.events 
{
	import flash.events.*;
	import QuickB2.*;
	import QuickB2.events.*;
	import QuickB2.objects.*;
	import revent.rEvent;
	import TopDown.*;
	import TopDown.ai.*;
	import TopDown.objects.*;
	use namespace qb2_friend;
	
	use namespace td_friend;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class tdTrackEvent extends rEvent
	{
		public static const TRACK_MOVED:String = "trackMoved";
		
		td_friend var _track:tdTrack;
		td_friend var _map:tdMap;
		
		public function tdTrackEvent(type:String = null) 
		{
			super(type);
		}
		
		public override function clone():rEvent
		{
			var evt:tdTrackEvent = new tdTrackEvent(type);
			evt._track  = _track;
			evt._map = _map;
			return evt;
		}
		
		public function get map():tdMap
		{
			return _map;
		}
		
		public function get track():tdTrack
		{
			return _track;
		}
	}
}