"""Ask the oracle a question; get an answer you can't argue with."""
import random

ANSWERS = ["It is certain.", "Ask again later.", "Outlook good.", "Very doubtful."]


def ask(question: str) -> str:
    random.seed(question)
    return random.choice(ANSWERS)


if __name__ == "__main__":
    print(ask(input("Your question: ")))
