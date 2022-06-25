using DataFrames

# Empty dataframe
DataFrame()

# Construct from pairs
DataFrame(
    "customer age" => [15, 20, 25],
    "first name" => ["Rohit", "Rahul", "Akshat"]
)

# Construct from Dict
DataFrame(Dict(
    :customer_age => [1, 2],
    :first_name => ["Baby1", "Baby2"]
))

# Construct from Tuple Array
DataFrame([(a = 1, b = 0), (a = 2, b = 0)])

# Construct from matrix (autonames)
DataFrame([1 0; 2 0], :auto)

# Construct from matrix (supplied names)
mat = [1 2 4 5; 15 58 69 41; 23 21 26 69]
nms = ["a", "b", "c", "d"]
DataFrame(mat, nms)

using CSV

# Reading from CSV into DataFrame
german_ref = 
    pathof(DataFrames) |>
    dirname |>
    x -> joinpath(x, "..", "docs", "src", "assets", "german.csv") |>
    path -> CSV.read(path, DataFrame)
german = copy(german_ref)

# Subsetting (no copy)
german.Sex
german."Sex"
german[!, :Sex]
german[!, "Sex"]
german.Sex === german[!, :Sex]
german.Sex === german[!, "Sex"]

# Subsetting (copy)
german[:, :Sex]
german[:, "Sex"]
german[:, :Sex] === german.Sex
colname = "Sex"
german[1:2, colname]

# Selecting columns 
names(german, AbstractString)
propertynames(german)

# Dealing with each column
eltype.(eachcol(german))

# Remove all rows (SQL TRUNCATE)
empty(german)
empty!(german)
german
german = copy(german_ref)

# Inspecting data frame
size(german)
size(german, 1)
size(german, 2)
nrow(german)
ncol(german)
describe(german)
describe(german, cols=1:3)
show(german, allrows=true)
show(german, allcols=true)
first(german, 6)
last(german, 6)
first(german) # Returns a dataframerow which is like a window 
last(german)

# Statistics 
using Statistics
mean(german.Age)
mapcols(id -> id .^2, german)

# Indexing 
german[1:5, [:Sex, :Age]]
german[1:5, :]
german[[1, 6, 15], :]
german[:, [:Age, :Sex]]
german[1, [:Sex]]

# Creating views of a dataframe 
view(german, :, 2:5)
@view german[end:-1:1, [1,4]]
# This view is more memory efficient and edit on the fly
@view german[1:5, 1]
@view german[2, 2]
@view german[3, 2:5]

# Mutating 

# Subsetting and indexing 
df1 = german[1:6, 2:4]
val = [80, 85, 98, 95, 78, 89]
df1.Age = val
df1
df1.Age === val
df1[1:3, :Job] = [2, 3, 2]
df1
df1[!, :Sex] = ["male", "female", "female", "transgender", "female", "male"]
df1
df1[3, 1:3] = [78, "male", 4]

# More indexing
df = DataFrame(r=1, x1=2, x2=3, y=4)
df[:, Not(:r)]
df[:, Between(:x1, :x2)]
df[:, All()]
df[:, Cols(x -> startswith(x, "x"))]
df[:, Cols(r"x", :)] # re-arrange

# Subsetting rows 
df = DataFrame(A=1:2:1000, B=repeat(1:10, inner=50), C=1:500)
df[df.A .> 500, :]
df[in.(df.A, Ref([1, 5, 601])), :]
subset(df, :A => a -> a .< 10, :C => c -> isodd.(c)) # works like dplyr::filter 

# Handling missing values 
df = DataFrame(x=[1, 2, missing, 4])
subset(df, :x => x -> coalesce.(iseven.(x), false)) # handle via coalesce OR
subset(df, :x => x -> iseven.(x), skipmissing=true) # use skipmissing keyword argument
# prefer to use subset and subset! instead of filter and filter! because it's more compatible 
# with other data frame methods.

# Selecting columns (dplyr::select), unlike in R this is completely swappable with transform
df = DataFrame(x1=[1, 2], x2=[3, 4], y=[5, 6])
select(df, :x1)
select(df, Not(:x1))
select(df, r"x")
select(df, :x1 => :boom)
select(df, :x1, :x2 => (x -> x .- minimum(x)) => :x2)
select(df, :x2, :x2 => ByRow(sqrt)) # ByRow allows transformation by row (kinda like dplyr::mutate_at)
select(df, AsTable(:) => ByRow(extrema) => [:lo, :hi]) #can return multiple numbers by using AsTable
select!(df, Between(:x1, :x2)) # in place selection

# Transform (dplyr::mutate) 
# For mutate it's select => function => output symbol which is refreshingly interesting
df = DataFrame(x1=[1, 2], x2=[3, 4], y=[5, 6])
transform(df, All() => +)
transform(df, [:x2, :x1] => ((x, y) -> (x .+ y).^2) => :x3)

# Summarise (dplyr::summarise)
df = DataFrame(A=1:4, B=["M", "F", "F", "M"])
describe(df)
describe(df[!, [:A]])
df = DataFrame(A=1:4, B=4.0:-1.0:1.0)
combine(df, names(df) .=> sum)

# Constructors is always copied by default 
x = [1, 2, 3]
df = DataFrame(x = x)
df.x = [3, 2, 1]
df
x

# Broadcasting assignment should always be done 
df = DataFrame(A = 1:4)
df[:, 1] .= 1
df

# Column Selectors (Not, Between, Cols, and All)
german = copy(german_ref)
german[:, Cols("Age", Between("Sex", "Job"))]

# Transformations 
using Statistics
# How to specify the transformations:
# [A] source_column => transformation => target_column_name (transform)
# [B] source_column => transformation (column names automatically generated)
# [C] source_column => target_column_name (renaming)
# [D] source_column 

# Combine: transformation is applied to all the rows and then return value is assigned/collapsed
combine(german, :Age => mean => :mean_age)

# Select: transformation to all rows but assigned to each row 
select(german, :Age => mean => :mean_age)

# Combine: you can supply various different transformations
combine(german, :Age => mean => :mean_age, :Housing => unique => :housing)
combine(german, :Age, :Housing => unique => :Housing) # will error, not broadcast compatible

# Select: use broadcasting to apply element-wise
select(german, :Sex => (x -> uppercase.(x)) => :Sex)
# Select: alternatively use ByRow to apply element-wise
select(german, :Sex => ByRow(uppercase) => :SEX)

# Rearrange to the front of the data frame
select(german, :Sex, :)

# More than one column makes them position arguments
select(german, :Age, :Job, [:Age, :Job] => (+) => :res)

# TODO: Full Documentation here: https://dataframes.juliadata.org/stable/man/getting_started/
