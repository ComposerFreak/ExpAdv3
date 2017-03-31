hook.Add("Expression3.LoadWiki", "Expression3.Wiki.RegisterExamples", function()
	EXPR_WIKI.RegisterExample("custom_class", 
[[interface fruit {
    method int health() {
        return 1;
    }
}

class food {
    int i = 0;
    
    food() {
        this.i = i;
    }
}

class apple extends food implements fruit {
    int s = 0;
    
    apple(int s) {
        this.s = s;
    }
    
    method int health() {
        return 100;
    }
}

class orange extends food implements fruit {
    int j = 0;
    
    orange(int j) {
        this.j = j;
    }
    
    method int health() {
        return 100;
    }
}

apple food1 = new apple(1);
orange food2 = new orange(2);
food food3 = (food) food1;
food food4 = (food) food2;
orange food5 = (orange) food3;
fruit food6 = (fruit) food1;
system.out(food2 instanceof food);]])

	EXPR_WIKI.RegisterExample("syntaxes", 
[[/*
	E3 - Example's 101
*/

//The name directive is used to set the script name.
@name "Example Gate Name";

//The model directive can be used to to set the model of the entity.
@model "models/nezzkryptic/e3_chip.mdl";

//The include directive is used to impliment code retained in an external file.
//@include "example.txt";

/*
	Notice how we have commented out the include, single line comments begin '//'.
	Whilst multi line comments are wrapped in (/* */).
*/

//To define a varible we must prefix the definition with its type.
boolean example1 = true;

//We can define multiple values of one type in this way.
int example2, example3 = 1, 2;

//Additionaly we can use the global prefix to define a variable as global.
global string exmaple4 = "example";

//You assign variables the normal way.
example2 = 30;

//You are also able to increase and decrease a value using arithmatic assigments.
example2, example3 += 1, 3; //1 is added to the value of example2 and 3 is added to the value of example3.

//If statements are same as you would expect (&& is and) (|| is or).
if (example1 && (example2 == 3 || example3 == 3))
{
	@output int Example;
	/*The output directive creates an output variable.
	this directive as well as the input directive can appear anywhere.
	The variables created are always nested to the block they where defined in.*/

	Example = (int) example1;
	//The casting operator '(type) value' takes the value on the right and tries to convert it to the class on the left.
}
//E3 supports multi comparison operations, this allows you to check one object against a list of objects at once.
elseif (example2 == [1,2,3,4])
{
	@input string MyString;
	//The input directive works exactly like the output directive but creates an input instead.

	MyString = example4;
	//Notice how input and output variable names have to be camel cased (1st letter is capitalized).
}
else
{
	int example5 = example1 ? example2 : exmple3;
	//The ternary operator selects between the last 2 values based on the condition.
}

//You can catch a script error using try catch, without your script crashing.
try
{
	error myError = new error("Example of thrown error.");
	//Some classes like errors and vectors use the 'new' keyword to create a new object.

	//You can also create and throw your own errors.
	system.throw(myError);
}
catch( theError )
{	
	string msg = theError.message();
	//To call a method on an object the syntax is object.method(...)

	system.print("Caught Error:", msg);
	//All functions are on libraries, the system library is where we find the print functions.
}

//For loops are as follows.
for (int i = 1; 20; 2)
{	
	system.out(i);
	//system.out is used to print to your Golem console.
}

//You can also do while loops.
while (example2 < 40)
{
	example2 = example2 + 1;

	//If ststaments can be preeced by a single statement, not just a block.
	if( example2 == 4)
		break; //Break is used to exit a loop.
}

table example6 = new table(1,2,3);
//Tables and arrays are the same thing in E3, notice again the use of the new keyword.
example6[1, int] = 22;
system.out(example6[1, int]);

//You can set and get values or an array or table in the same way as e2.

//Foreach loops will iterate through a table.
foreach (int key as int value in example6)
//If you have no need for a key then 'int key as' is not needed.
{
	system.out("value ", value);

	//Continue is used to break the current iteration and move onto the next.
	continue;

	system.out("key ", key);
}

//You can define a function in two ways, firstly traditonal.
function egFunction1(int a)
{
	return a, a + 1, a + 2;
	//You can return more than one value of the return class.
}

int a, b, c = egFunction1(1);
//Returning that way can be useful.

//Secondly inline.
function egFunction2 = function(int a, int b)
{
	return a + b;
}

//Functions defined inline, can not be called directly.
int example7 = system.invoke(number, 1, egFunction2, 2, 4);
//System.invoke takes the expected return class as well as the anount of values returned before the function to invoke.

//Delegates are used to define templates for functions.
delegate egFunction3(int, int) {
	return 1; //this is the ammount of values returned.
}

//You can then assign a function to this template.
egFunction3 = egFunction2;

//The inline function egFunction2 can now be called , using egFunction3.
int example8 = egFunction3(2, 4);

//All user functions are first class.
event.add("Think", "example", function()
{
	//This means you can tie a function to an event.
});

//E3 also has full object oriented programming.
class exampleClass
{
	int atribute1 = 0;
	//Classes support atributes.

	//Constructors are used to create a class.
	exampleClass(int value)
	{
		this.atribute1 = value;
	}

	//As well as methods.
	method int getValue()
	{
		return atribute1;
		//This is method is redundant as you can do object.atribute1 from anywhere.
	}
}

exampleClass example8 = new exampleClass(42);
//The new keyword is used to call the constructor.

//Classes may laso extend others.
class anotherClass extends exampleClass
{
	anotherClass()
	{
		//Do nothing.
	}
}

//E3 also adds interfaces.
interface exampleInterface
{	
	//Iinterfaces are used to create templates for methods.
	method int egMethod(int, int)
	{
		return 1; //This is the ammount of values returned.
	}
}

class exampleClass3 implements exampleInterface
{
	exampleClass3()
	{
		//Do nothing.
	}

	//Is this interafce method is missing you will get an error.
	method int egMethod(int a, int b) 
	{
		return a / b;
	}

}

exampleClass3 example9 = new exampleClass3();

//Interfaces are useful, you can treat interfaces as a class refrence for objects.
exampleInterface example10 = (exampleClass3) example9;

//Instaceof allows us to check is an object is, extends or impliments a specific class.
system.out(example9 instanceof exampleInterface);; //Spits out true.]])
end)