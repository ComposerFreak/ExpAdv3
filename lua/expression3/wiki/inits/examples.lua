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
end)