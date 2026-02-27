#!/usr/bin/env nu
def main [] {
    let w = (term size | get columns)

    let user = "Ryuko"
    let art = (open ~/dotfiles/nu/hello.txt)
    let quote = (^~/dotfiles/nu/kotofetch --border true | into string | str trim)

    let greetings = [
        $"おかえり、($user)。"
        $"また会えたね、($user)。"
        $"よく来たね、($user)。"
        $"待ってたよ、($user)。"
        $"さあ、始めよう、($user)。"
        $"今日も頑張ろう、($user)。"
        $"いい日になるよ、($user)。"
    ]
    let greeting = ($greetings | get (random int 0..((($greetings | length) - 1))))

    # Helper: compute left padding to center a string of given display width
    def pad-for [dw: int, w: int] {
        let p = (($w - $dw) / 2 | math floor)
        "" | fill -c " " -w ([0 $p] | math max)
    }

    # Center each line of the art
    let centered_art = ($art | lines | each {|line|
        let dw = ($line | str stats | get unicode-width)
        let spaces = (pad-for $dw $w)
        $"($spaces)($line)"
    } | str join "\n")

    # Center greeting
    let g_dw = ($greeting | str stats | get unicode-width)
    let g_spaces = (pad-for $g_dw $w)

    # Center each kotofetch line independently (no border, just text)
    let centered_quote = ($quote | lines | each {|l| $l | str trim} | where {|l| $l != ""} | each {|line|
        let dw = ($line | str stats | get unicode-width)
        let spaces = (pad-for $dw $w)
        $"($spaces)($line)"
    } | str join "\n")

    print $centered_art
    print $"($g_spaces)($greeting)"
    print ""
    print $centered_quote
}
