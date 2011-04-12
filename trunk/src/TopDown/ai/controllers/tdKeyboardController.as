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

package TopDown.ai.controllers 
{
	import flash.display.*;
	import flash.events.*;
	import flash.ui.*;
	import QuickB2.*;
	import QuickB2.misc.*;
	
	import TopDown.*;
	use namespace td_friend;

	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class tdKeyboardController extends tdController
	{
		public const keysForward:Vector.<uint> = new Vector.<uint>();
		public const keysBack:Vector.<uint> = new Vector.<uint>();
		public const keysLeft:Vector.<uint> = new Vector.<uint>();
		public const keysRight:Vector.<uint> = new Vector.<uint>();
		
		private var _keySource:Stage;
	
		public function tdKeyboardController(keySource:Stage):void
		{
			_keySource = keySource;
			
			qb2Keyboard.makeSingleton(keySource);
			_keyboard = qb2Keyboard.singleton;
			
			keysForward.push( 87, Keyboard.UP    );
			keysBack.push(    83, Keyboard.DOWN  )
			keysLeft.push(    65, Keyboard.LEFT  );
			keysRight.push(   68, Keyboard.RIGHT );
			
			if ( (this as Object).constructor == tdKeyboardController )
			{
				throw qb2_errors.ABSTRACT_CLASS_ERROR;
			}
		}
		
		protected override function activated():void
		{
			qb2Keyboard.singleton.addEventListener(KeyboardEvent.KEY_DOWN, keyPressed, false, 0, true);
			qb2Keyboard.singleton.addEventListener(KeyboardEvent.KEY_UP,   keyPressed, false, 0, true);
		}
		
		protected override function deactivated():void
		{
			qb2Keyboard.singleton.removeEventListener(KeyboardEvent.KEY_DOWN, keyPressed   );
			qb2Keyboard.singleton.removeEventListener(KeyboardEvent.KEY_UP,   keyPressed   );
		}
		
		protected override function update():void
		{
			
		}
		
		private function keyPressed(evt:KeyboardEvent):void
		{
			if ( brainPort.open )
			{
				keyEvent(evt.keyCode, evt.type == KeyboardEvent.KEY_DOWN);
			}
		}

		protected virtual function keyEvent(keyCode:uint, down:Boolean):void
		{
		}
		
		public function get keyboard():qb2Keyboard
			{  return _keyboard;  }
		private var _keyboard:qb2Keyboard;
	}
}