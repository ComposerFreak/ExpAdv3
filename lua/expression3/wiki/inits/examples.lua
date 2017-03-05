hook.Add("Expression3.LoadWiki", "Expression3.Wiki.RegisterExamples", function()
	EXPR_WIKI.RegisterExample("custom_class", 
[[class vec {
    int x = 0;
    int y = 0;
    int z = 0;
    constructor vec(int x, int y, int z) {
        this.x = x;
        this.y = y;
        this.z = z;
    }
    method vector toVector() {
        return new vector(x, y, z);
    }
    method vec add(vec a) {
        return new vec(x + a.x, y + a.y, z + a.z);
    }
    method vec sub(vec a) {
        return new vec(x - a.x, y - a.y, z - a.z);
    }
    tostring() {
        return "vec(" + x + "," + y + "," + z + ")";
    }
}
vec a = new vec(1,2,3);
system.out(a.add(a));]])
end)