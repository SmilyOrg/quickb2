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
	import As3Math.geo2d.*;
	import com.bit101.components.*;
	import flash.display.*;
	import flash.events.*;
	import flash.utils.*;
	
	
	/**
	 * A bare bones preloader.  You can use this class for prototypes/demos that you
	 * just want to throw up on the web and show to clients or testers or something.
	 * 
	 * @author Doug Koellmer
	 */
	public class qb2FlashPreloader extends MovieClip
	{
		private var _upperLeft:amPoint2d = new amPoint2d();
		private var _loadingBar:ProgressBar = new ProgressBar();
		private var _stage:Stage;
		private var _label:Label = new Label();
		
		public var loadingText:String = "Loading...";
		public var mainClassName:String = "Main";
		
		public var autoRemove:Boolean = true;
		
		public function qb2FlashPreloader() 
		{
			_singleton = this;
			
			addEventListener(Event.ENTER_FRAME, checkFrame);
			loaderInfo.addEventListener(ProgressEvent.PROGRESS, progress);
			
			if ( stage )
			{
				addedToStage();
			}
			else
			{
				addEventListener(Event.ADDED_TO_STAGE, addedToStage);
			}
		}
		
		public function get theStage():Stage
		{
			return _stage;
		}
		
		private function addedToStage(evt:Event = null):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, addedToStage);
			
			_stage = stage;
			addChild(_loadingBar);
			addChild(_label);
			_stage.scaleMode = StageScaleMode.NO_SCALE;
			_stage.align = StageAlign.TOP_LEFT;
			_stage.addEventListener(Event.RESIZE, stageResized);
			stageResized(null);
			
			updateText(loadingText + "0%");
		}
		
		public static function get singleton():qb2FlashPreloader
			{  return _singleton;  }
		private static var _singleton:qb2FlashPreloader = null;
		
		private function stageResized(evt:Event):void
		{			
			alignLoadingBar();
			alignLoadingText();
		}
		
		private function alignLoadingBar():void
		{
			if ( !_loadingBar )  return;
			
			_loadingBar.x = _upperLeft.x + _stage.stageWidth / 2 - _loadingBar.width / 2;
			_loadingBar.y = _upperLeft.y + _stage.stageHeight / 2 - _loadingBar.height / 2;
		}
		
		private function alignLoadingText():void
		{
			if ( !_label )  return;
			
			_label.x = _loadingBar.x + _loadingBar.width / 2 - _label.width / 2;
			_label.y = _loadingBar.y + _loadingBar.height;
		}
		
		public final function updateProgress(value:Number):void
		{
			_loadingBar.value = value;
		}
		
		public final function updateText(string:String):void
		{
			_label.text = string;
			_label.draw();
			
			alignLoadingText();
		}
		
		public final function finish():void
		{
			removeChild(_loadingBar);
			removeChild(_label);
			
			_loadingBar = null;
			_label = null;
		}
		
		private function progress(evt:ProgressEvent):void
		{
			var value:Number = (evt.bytesLoaded as Number) / (evt.bytesTotal as Number);
			updateProgress(value);
			updateText(loadingText + Math.round(value * 100) + "%");
		}
		
		private function checkFrame(e:Event):void 
		{
			if (currentFrame == totalFrames) 
			{
				stop();
				loadingFinished();
			}
		}
		
		private function loadingFinished():void 
		{
			removeEventListener(Event.ENTER_FRAME, checkFrame);
			loaderInfo.removeEventListener(ProgressEvent.PROGRESS, progress);
			
			updateProgress(1.0);
			updateText(loadingText + "100%");
			
			addMain();
		}
		
		private function addMain():void 
		{
			//--- Get the "Main" class name through a compiler constant.
			var classDef:Class = getDefinitionByName(mainClassName) as Class;
			var main:Sprite = new classDef as Sprite;
			if (parent == stage)
				stage.addChildAt(main, 0);
			else
				addChildAt(main, 0);
				
			if ( autoRemove )
			{
				_stage.removeChild(this);
			}
		}
	}
}