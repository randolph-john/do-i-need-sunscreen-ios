import SwiftUI

struct QuizQuestion {
    let id: Int
    let question: String
    let answers: [(text: String, points: Int)]
}

let quizQuestions: [QuizQuestion] = [
    QuizQuestion(id: 1, question: "What is your natural eye color?", answers: [
        ("Light blue, light gray, or light green", 0),
        ("Blue, gray, or green", 1),
        ("Hazel", 2),
        ("Light brown", 3),
        ("Dark brown", 4),
        ("Brownish black", 5),
    ]),
    QuizQuestion(id: 2, question: "What is your natural hair color?", answers: [
        ("Red or light blonde", 0),
        ("Blonde", 1),
        ("Dark blonde", 2),
        ("Light brown", 3),
        ("Dark brown", 4),
        ("Black", 5),
    ]),
    QuizQuestion(id: 3, question: "What is your natural skin color (areas not exposed to sun)?", answers: [
        ("Pink", 0),
        ("Pale", 7000),
        ("Olive", 14000),
        ("Light brown", 21000),
        ("Brown", 28000),
        ("Dark brown or black", 35000),
    ]),
    QuizQuestion(id: 4, question: "How many freckles do you have on unexposed areas of your skin?", answers: [
        ("Very many", 0),
        ("Many", 1),
        ("Several", 2),
        ("A few", 3),
        ("Almost none", 4),
        ("None", 5),
    ]),
    QuizQuestion(id: 5, question: "How does your skin react to the sun (with no sunscreen)?", answers: [
        ("Always blisters and peels", 0),
        ("Sometimes blisters and peels", 1),
        ("Rarely blisters and peels", 2),
        ("Burns sometimes", 3),
        ("Burns rarely", 4),
        ("Never burns", 5),
    ]),
    QuizQuestion(id: 6, question: "Does your skin tan (with no sunscreen)?", answers: [
        ("Never - I just burn and peel", 0),
        ("Seldom", 1),
        ("Sometimes", 2),
        ("Often", 3),
        ("Nearly always", 4),
        ("Always", 5),
    ]),
    QuizQuestion(id: 7, question: "How deeply do you tan (with no sunscreen)?", answers: [
        ("Not at all", 0),
        ("Minimal", 1),
        ("Light tan", 2),
        ("Moderate tan", 3),
        ("Dark tan", 4),
        ("Very dark tan", 5),
    ]),
    QuizQuestion(id: 8, question: "How sensitive is your face to the sun (with no sunscreen)?", answers: [
        ("Very sensitive", 0),
        ("Sensitive", 1),
        ("Somewhat sensitive", 2),
        ("Somewhat resistant", 3),
        ("Resistant", 4),
        ("Very resistant - never had a problem", 5),
    ]),
]

func calculateSkinType(totalPoints: Int) -> SkinType {
    if totalPoints <= 6000 { return .typeI }
    if totalPoints <= 13000 { return .typeII }
    if totalPoints <= 20000 { return .typeIII }
    if totalPoints <= 27000 { return .typeIV }
    if totalPoints <= 34000 { return .typeV }
    return .typeVI
}

struct SkinTypeQuizView: View {
    @Binding var isPresented: Bool
    @ObservedObject var preferences: UserPreferences

    @State private var currentQuestion = 0
    @State private var answers: [Int: Int] = [:]
    @State private var showResult = false
    @State private var resultSkinType: SkinType?

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if showResult, let skinType = resultSkinType {
                    resultView(skinType: skinType)
                } else {
                    quizView
                }
            }
            .navigationTitle("Skin Type Quiz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }

    private var quizView: some View {
        let q = quizQuestions[currentQuestion]
        let progress = Double(currentQuestion + 1) / Double(quizQuestions.count)

        return VStack(spacing: 16) {
            ProgressView(value: progress)
                .padding(.horizontal)

            Text("Question \(currentQuestion + 1) of \(quizQuestions.count)")
                .font(.caption)
                .foregroundColor(.secondary)

            Text(q.question)
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(Array(q.answers.enumerated()), id: \.offset) { index, answer in
                        Button {
                            selectAnswer(questionId: q.id, points: answer.points)
                        } label: {
                            HStack {
                                Text(answer.text)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                if answers[q.id] == answer.points {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(answers[q.id] == answer.points
                                          ? Color.accentColor.opacity(0.1)
                                          : Color(.systemGray6))
                            )
                        }
                    }
                }
                .padding(.horizontal)
            }

            HStack {
                if currentQuestion > 0 {
                    Button("Back") {
                        currentQuestion -= 1
                    }
                    .buttonStyle(.bordered)
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    private func resultView(skinType: SkinType) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Your Skin Type")
                .font(.title2)

            Circle()
                .fill(Color(hex: skinType.swatchColorHex))
                .frame(width: 100, height: 100)
                .overlay(
                    Circle().stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )

            Text(skinType.label)
                .font(.title3.bold())

            Text(skinType.description)
                .foregroundColor(.secondary)

            Spacer()

            Button("Use This Skin Type") {
                preferences.skinType = skinType
                preferences.hasCompletedQuiz = true
                isPresented = false
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()
        }
        .padding()
    }

    private func selectAnswer(questionId: Int, points: Int) {
        answers[questionId] = points

        if currentQuestion < quizQuestions.count - 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                currentQuestion += 1
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                let totalPoints = answers.values.reduce(0, +)
                resultSkinType = calculateSkinType(totalPoints: totalPoints)
                showResult = true
            }
        }
    }
}

