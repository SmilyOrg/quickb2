/**
 * Copyright (c) 2011 Doug Koellmer
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

package QuickB2.debugging.logging 
{
	/**
	 * Creates a string useful for printing with custom variables.
	 * 
	 * @author Doug Koellmer
	 */
	public function qb2_toString(object:Object, className:String, variableNames:Array = null):String
	{
		var toReturn:String = qb2_debugPrintSettings.classBrackets.charAt(0) + className + qb2_debugPrintSettings.variableBrackets.charAt(0);
		
		if ( !variableNames )
		{
			variableNames = qb2_debugPrintSettings.classToVariableMap[className];
		}
		
		var varDelimiter:String = qb2_debugPrintSettings.variableDelimiter;
		if ( variableNames )
		{
			var length:int = variableNames.length;
			for (var i:int = 0; i < length; i++)
			{
				var varName:String = variableNames[i] as String;
			
				if ( !varName )  continue;
				
				var variable:Object = object[varName];
				toReturn += varName + qb2_debugPrintSettings.equalityCharacter + variable;
				
				if ( i < length -1 )
				{
					toReturn += varDelimiter;
				}
			}
		}
		else
		{
			toReturn += "no variables provided";
		}
		
		toReturn += qb2_debugPrintSettings.variableBrackets.charAt(1) + qb2_debugPrintSettings.classBrackets.charAt(1);
		
		return toReturn;
	}
}