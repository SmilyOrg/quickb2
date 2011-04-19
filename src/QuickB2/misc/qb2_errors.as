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
	/**
	 * Just a central repository for all the runtime errors that QuickB2 throws if you're being naughty.
	 * 
	 * @author Doug Koellmer
	 */
	public class qb2_errors
	{
		/// Thrown when you try to instantiate a base class that should never be instantiated directly.
		public static const ABSTRACT_CLASS_ERROR:Error = new Error("This class acts purely as a base class and cannot be instantiated directly.");
		
		/// Thrown when you try to manipulate a joint's force/torque when the joint is behaving as an optimized spring.
		public static const OPT_SPRING_ERROR:Error = new Error("To use this property, either optimizedSpring must be false, or springK must be 0.");
		
		/// Thrown when you to try to add an object twice to the same or different containers.
		public static const ALREADY_HAS_PARENT_ERROR:Error = new Error("The object added already has a parent.");
		
		/// Thrown when you try to add null to a container.
		public static const ADDING_NULL_ERROR:Error = new Error("Attempted to add a null object.");
		
		/// Thrown when a subclass of qb2EventDispatcher attempts to retrieve either an event bit or a cached event that doesn't exist.
		public static const EVENT_NOT_FOUND:Error = new Error("The event type was not found in the event map.");
		
		public static const WRONG_PARENT:Error = new Error("Object's parent doesn't match up.");
		
		/// Thrown when qb2EventDispatcher has no room left in its event cache.  There are 32 slots available.
		public static const EVENT_CACHE_FULL:Error = new Error("qb2EventDispatcher's event cache is full.");
		
		public static const LOAD_IN_PROGRESS:Error = new Error("qb2FlashLoader is already loading something.");
		
		public static const BAD_DISTANCE_QUERY:Error = new Error("Illegal distance query...both objects must be in the world and not descendants of each other.");
	
		public static const NUMBER_PROPERTY_SLOTS_FULL:Error = new Error("No more inheritable number properties can be made.");
		
		public static const NOT_IN_WORLD:Error = new Error("Object must be in-world.");
		
		public static const CLONE_ERROR:Error = new Error("This object cannot be cloned.");
		
		public static const ILLEGAL_FLAG_ASSIGNMENT:Error = new Error("Attempted to use a flag reserved for internal use.");
	}
}