#!/bin/env ruby
# encoding: utf-8

class Variable < Struct.new(:name)
    def to_s
        name.to_s
    end

    def inspect
        "«#{self}»"
    end

    def reducible?
        true
    end

    def reduce(environment)
        environment[name]
    end
end


class Number < Struct.new(:value)
    def to_s
        value.to_s
    end

    def inspect
        "«#{self}»"
    end

    def reducible?
        false
    end

    def reduce
        puts('No longer reducible')
        self
    end
end

class Add < Struct.new(:left, :right)
    def to_s
        "#{left} + #{right}"
    end

    def inspect
        "«#{self}»"
    end

    def reducible?
        true
    end

    def reduce(environment)
        if left.reducible?
            Add.new(left.reduce(environment), right)
        elsif right.reducible?
            Add.new(left, right.reduce(environment))
        else
            Number.new(left.value + right.value)
        end
    end
end

class Multiply < Struct.new(:left, :right)
    def to_s
        "#{left} + #{right}"
    end

    def inspect
        "«#{self}»"
    end

    def reducible?
        true
    end

    def reduce(environment)
        if left.reducible?
            Multiply.new(left.reduce(environment), right)
        elsif right.reducible?
            Multiply.new(left, right.reduce(environment))
        else
            Number.new(left.value * right.value)
        end
    end
end


class Boolean < Struct.new(:value)
    def to_s
        value.to_s
    end

    def inspect
        "«#{self}»"
    end

    def reducible?
        false
    end
end


class LessThan < Struct.new(:left, :right)
    def to_s
        "«#{left} < #{right}»"
    end

    def inspect
        "«#{self}»"
    end

    def reducible?
        true
    end

    def reduce(environment)
        if left.reducible?
            LessThan.new(left.reduce(environment), right)
        elsif right.reducible?
            LessThan.new(left, right.reduce(environment))
        else
            Boolean.new(left.value < right.value)
        end
    end
end


class GreaterThan < Struct.new(:left, :right)
    def to_s
        "«#{left} > #{right}»"
    end

    def inspect
        "«#{self}»"
    end

    def reducible?
        true
    end

    def reduce(environment)
        if left.reducible?
            GreaterThan.new(left.reduce(environment), right)
        elsif right.reducible?
            GreaterThan.new(left, right.reduce(environment))
        else
            Boolean.new(left.value > right.value)
        end
    end
end


# # Example expression to parse.
# env = {}
# expression = Add.new(
#     Multiply.new(Number.new(1), Number.new(2)),
#     Multiply.new(Number.new(3), Number.new(4))
# )
# # => «1 * 2 + 3 * 4»
# expression.reducible?
# # => true
# expression.reduce(env)
# # => «2 + 3 * 4»
# expression.reduce(env).reducible?
# # => true
# expression.reduce(env).reduce(env)
# # => «2 + 12»
# expression.reduce(env).reduce(env).reducible?
# # => true
# expression.reduce(env).reduce(env).reduce(env)
# # => «14»
# expression.reduce(env).reduce(env).reduce(env).reducible?
# # => false



class Machine < Struct.new(:statement, :environment)
    def step
        self.statement, self.environment = statement.reduce(environment)
    end

    def run
        while statement.reducible?
            puts "#{statement}, #{environment}"
            step
        end

        puts "#{statement}, #{environment}"
    end
end

# Example use of Machine to parse expression.
# Machine.new(
#     Add.new(
#         Multiply.new(Number.new(1), Number.new(2)),
#         Multiply.new(Number.new(3), Number.new(4))
#     ), {}
# ).run
# # 1 * 2 + 3 * 4
# # 2 + 3 * 4
# # 2 + 12
# # 14
# # => nil

# Machine.new(
#     Add.new(Variable.new(:x), Variable.new(:y)),
#     { x: Number.new(3), y: Number.new(4) }
# ).run

class DoNothing
    def to_s
        'do-nothing'
    end

    def inspect
        "«#{self}»"
    end

    def ==(other_statement)
        other_statement.instance_of?(DoNothing)
    end

    def reducible?
        false
    end
end


class Assign < Struct.new(:name, :expression)
    def to_s
        "#{name} = #{expression}"
    end

    def inspect
       "«#{self}»"
    end

    def reducible?
        true
    end

    def reduce(environment)
        if expression.reducible?
            [Assign.new(name, expression.reduce(environment)),
             environment]
        else
            [DoNothing.new, environment.merge({name => expression})]
        end
    end
end


# statement = Assign.new(
#     :x,
#     Add.new(Variable.new(:x), Number.new(1))
# )
# # "«x = x + 1»"
# environment = {x: Number.new(2)}
# # {x: «2»}
# statement.reducible?
# # true
# statement, environment = statement.reduce(environment)
# # [«x = 2 + 1», {x: «2»}]
# statement, environment = statement.reduce(environment)
# # [«x = 3», {x: «2»}]
# statement, environment = statement.reduce(environment)
# # [«do-nothing», {x: «3»}]
# statement.reducible?
# # false


# Machine.new(
#     Assign.new(:x, Add.new(Variable.new(:x), Number.new(1))),
#     {x: Number.new(2)}
# ).run
# # x = x + 1, {:x=>«2»}
# # x = 2 + 1, {:x=>«2»}
# # x = 3, {:x=>«2»}
# # do-nothing, {:x=>«3»}
# # => nil



class If < Struct.new(:condition, :consequence, :alternative)
    def to_s
        "if (#{condition}) { #{consequence} } else { #{alternative} }"
    end

    def inspect
        "«#{self}»"
    end

    def reducible?
        true
    end

    def reduce(environment)
        if condition.reducible?
            [
                If.new(condition.reduce(environment),consequence,alternative),
                environment
            ]
        else
            case condition
            when Boolean.new(true)
                [consequence, environment]
            when Boolean.new(false)
                [alternative, environment]
            end
        end
    end
end


# Machine.new(
#     If.new(
#         Variable.new(:x),
#         Assign.new(:y, Number.new(1)),
#         Assign.new(:y, Number.new(2))
#     ),
#     { x: Boolean.new(true) }
# ).run
# # if (x) { y = 1 } else { y = 2 }, {:x=>«true»}
# # if (true) { y = 1 } else { y = 2 }, {:x=>«true»}
# # y = 1, {:x=>«true»}
# # do-nothing, {:x=>«true», :y=>«1»}
# # => true


class Sequence < Struct.new(:first, :second)
    def to_s
        "#{first}; #{second}"
    end

    def inspect
        "«#{self}»"
    end

    def reducible?
        true
    end

    def reduce(environment)
        case first
        when DoNothing.new
            [second, environment]
        else
            reduced_first, reduced_environment = first.reduce(environment)
            [Sequence.new(reduced_first, second), reduced_environment]
        end
    end
end



# Machine.new(
#     Sequence.new(
#         Assign.new(
#             :x,
#             Add.new(Number.new(1), Number.new(1))),
#         Add.new(Variable.new(:x), Number.new(3))
#     ),
#     {}
# ).run
# # x = 1 + 1; x + 3, {}
# # x = 2; x + 3, {}
# # do-nothing; x + 3, {:x=>«2»}
# # x + 3, {:x=>«2»}
# # 2 + 3,
# # 5,
# # => true

class While < Struct.new(:condition, :body)
    def to_s
        "while #{condition} { #{body} }"
    end

    def inspect
        "«#{self}»"
    end

    def reducible?
        true
    end

    def reduce(environment)
        [
            If.new(
                condition,
                Sequence.new(body, self),
                DoNothing.new),
            environment
        ]
    end
end


Machine.new(
    While.new(
        LessThan.new(Variable.new(:x), Number.new(5)),
        Assign.new(:x, Multiply.new(Variable.new(:x), Number.new(3)))
    ),
    { x: Number.new(1) }
).run
# while «x < 5» { x = x + 3 }, {:x=>«1»}
# if («x < 5») { x = x + 3; while «x < 5» { x = x + 3 } } else { do-nothing }, {:x=>«1»}
# if («1 < 5») { x = x + 3; while «x < 5» { x = x + 3 } } else { do-nothing }, {:x=>«1»}
# if (true) { x = x + 3; while «x < 5» { x = x + 3 } } else { do-nothing }, {:x=>«1»}
# x = x + 3; while «x < 5» { x = x + 3 }, {:x=>«1»}
# x = 1 + 3; while «x < 5» { x = x + 3 }, {:x=>«1»}
# x = 3; while «x < 5» { x = x + 3 }, {:x=>«1»}
# do-nothing; while «x < 5» { x = x + 3 }, {:x=>«3»}
# while «x < 5» { x = x + 3 }, {:x=>«3»}
# if («x < 5») { x = x + 3; while «x < 5» { x = x + 3 } } else { do-nothing }, {:x=>«3»}
# if («3 < 5») { x = x + 3; while «x < 5» { x = x + 3 } } else { do-nothing }, {:x=>«3»}
# if (true) { x = x + 3; while «x < 5» { x = x + 3 } } else { do-nothing }, {:x=>«3»}
# x = x + 3; while «x < 5» { x = x + 3 }, {:x=>«3»}
# x = 3 + 3; while «x < 5» { x = x + 3 }, {:x=>«3»}
# x = 9; while «x < 5» { x = x + 3 }, {:x=>«3»}
# do-nothing; while «x < 5» { x = x + 3 }, {:x=>«9»}
# while «x < 5» { x = x + 3 }, {:x=>«9»}
# if («x < 5») { x = x + 3; while «x < 5» { x = x + 3 } } else { do-nothing }, {:x=>«9»}
# if («9 < 5») { x = x + 3; while «x < 5» { x = x + 3 } } else { do-nothing }, {:x=>«9»}
# if (false) { x = x + 3; while «x < 5» { x = x + 3 } } else { do-nothing }, {:x=>«9»}
# do-nothing, {:x=>«9»}
# => true