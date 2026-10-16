# Focused Ruby deviations

- Issue 135 attribute ordering: RuboCop Metrics/MethodLength flags the 14-line real-QEA fixture builder, and Metrics/BlockLength flags its six-example public pipeline regression group. Keep the fixture together and the directly related controls in one group; splitting them would obscure the input collections and ordering contract.
